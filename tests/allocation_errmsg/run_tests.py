#!/usr/bin/env python3
"""Allocation descriptor, error-message and ownership checks.

Uses the CLI directly; GNU Fortran is only an oracle, never an execution backend.
Compiler runs occur in fresh temporary directories to prevent stale .mod reuse.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import math
import platform
import re
import subprocess
import tempfile
import contextlib

ROOT = Path(__file__).resolve().parent


def execute(argv, cwd=None):
    try:
        proc = subprocess.run([str(arg) for arg in argv], cwd=cwd or ROOT,
                              text=True, capture_output=True, timeout=15,
                              stdin=subprocess.DEVNULL)
        return dict(code=proc.returncode, out=proc.stdout, err=proc.stderr, argv=[str(arg) for arg in argv])
    except subprocess.TimeoutExpired as exc:
        def txt(value):
            return value.decode(errors='replace') if isinstance(value, bytes) else value or ''
        return dict(code=None, out=txt(exc.stdout), err='TIMEOUT '+txt(exc.stderr))
    except OSError as exc:
        return dict(code=None, out='', err=str(exc))


def compare(actual, expected, rel_tol=2e-6, abs_tol=1e-7, mode="tokens"):
    # Empty output means no bytes, not an empty token stream.
    if expected == "":
        return actual == ""
    if mode == "lines":
        # Permit the conventional final record terminator, preserving padding
        # and extra blank records rather than stripping all trailing newlines.
        return (actual != "" and
                actual.replace("\r\n", "\n").removesuffix("\n") ==
                expected.replace("\r\n", "\n").removesuffix("\n"))
    actual, expected = actual.split(), expected.split()
    if len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        try:
            a, b = float(got.replace('D', 'E').replace('d', 'e')), float(want)
        except ValueError:
            if got != want:
                return False
        else:
            if not math.isfinite(a):
                return False
            if re.fullmatch(r'[+-]?\d+', want):
                if (int(got) != int(want) if re.fullmatch(r'[+-]?\d+', got) else a != int(want)):
                    return False
            elif not math.isclose(a, b, rel_tol=rel_tol, abs_tol=abs_tol):
                return False
    return True


def candidate_errors(case, check, result):
    category = case['category']
    expected_check = 0 if category in ('success', 'runtime') else 1
    expected_run = 0 if category == 'success' else 2 if category == 'runtime' else 1
    errors = []
    for name, stage, expected in [('check', check, expected_check), ('run', result, expected_run)]:
        if stage['code'] != expected:
            errors.append(f'{name} expected exit {expected}, got {stage["code"]}')
        if expected and not stage['err'].strip():
            errors.append(name+': missing error diagnostic')
        if not expected and stage['err'] != '':
            errors.append(name+': unexpected success diagnostic')
    if check['out'] != '':
        errors.append('check stdout leak')
    if not compare(result['out'], case['expected_stdout'],
                   case.get('rel_tol',2e-6),case.get('abs_tol',1e-7),case.get('compare_mode','tokens')):
        errors.append('stdout mismatch/leak')
    if case.get('diagnostic'):
        diagnostic = '\n'.join(re.sub(r'^.*?:\d+:\d+:', '', line)
                               for line in result['err'].splitlines())
        if case['diagnostic'].lower() not in diagnostic.lower():
            errors.append('missing diagnostic '+case['diagnostic'])
    return errors



def gnu_compile_errors(case, result):
    if case['baseline'] == 'reject':
        return [] if result['code'] == 1 and result['err'].strip() and result['out'] == '' else ['GNU did not cleanly reject']
    return [] if result['code'] == 0 and result['out'] == '' else ['GNU compile failed or stdout leak']


def gnu_success_errors(case, result):
    errors = []
    if result['code'] != 0 or not compare(result['out'], case['expected_stdout'],
            case.get('rel_tol',2e-6),case.get('abs_tol',1e-7),case.get('compare_mode','tokens')):
        errors.append('GNU oracle mismatch')
    if result['err'] != '':
        errors.append('GNU unexpected success diagnostic')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', help='Single executable path (no shell command)')
    parser.add_argument('--gfortran')
    parser.add_argument('--only', default='', help='Regular expression selecting case names')
    parser.add_argument('--result', default='results.json')
    parser.add_argument('--artifacts', help='Retained GNU build directory (default: a fresh system temporary directory)')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    initial_candidate_hash = None
    if args.candidate:
        candidate_path = Path(args.candidate).expanduser().resolve()
        if not candidate_path.is_file():
            parser.error('Candidate executable does not exist: '+str(candidate_path))
        args.candidate = str(candidate_path)
        initial_candidate_hash = hashlib.sha256(candidate_path.read_bytes()).hexdigest()
    artifacts = None
    if args.gfortran:
        artifacts = Path(args.artifacts).resolve() if args.artifacts else Path(tempfile.mkdtemp(prefix='allocation-oracles-'))
        artifacts.mkdir(parents=True, exist_ok=True)
    records = []
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        if not re.search(args.only, case['name']):
            continue
        source = ROOT/case['source']
        row = dict(case=case, errors=[])
        if args.gfortran:
            if case['baseline'] == 'skip':
                row['gnu_skipped'] = True
            else:
                with contextlib.nullcontext(tempfile.mkdtemp(prefix=case['name']+'-', dir=artifacts)) as folder:
                    binary = Path(folder)/'reference'
                    compiled = execute([args.gfortran, '-std=f2018', '-pedantic-errors',
                                        '-fcheck=all', '-O0', source, '-o', binary], folder)
                    row['gnu_compile'] = compiled
                    row['errors'] += gnu_compile_errors(case, compiled)
                    if case['baseline'] == 'reject' or compiled['code'] != 0:
                        pass
                    elif case['baseline'] == 'runtime':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        if ran['code'] != case.get('gnu_exit',2) or not ran['err'].strip() or not compare(ran['out'], case['expected_stdout']):
                            row['errors'].append('GNU runtime rejection/output mismatch')
                        if case.get('gnu_diagnostic',case.get('diagnostic','')).lower() not in ran['err'].lower():
                            row['errors'].append('GNU runtime diagnostic mismatch')
                    elif case['baseline'] == 'run':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        row['errors'] += gnu_success_errors(case, ran)
        if args.candidate:
            checked = execute([args.candidate, '--check', source])
            ran = execute([args.candidate]+case.get('args', [])+[source])
            row['check'], row['run'] = checked, ran
            row['errors'] += candidate_errors(case, checked, ran)
        status = 'FAIL '+', '.join(row['errors']) if row['errors'] else 'PASS'
        if row.get('gnu_skipped') and not args.candidate:
            status = 'SKIP (interpreter safety policy; no GNU oracle claimed)'
        print(case['name']+': '+status, flush=True)
        records.append(row)
    if not records:
        parser.error('No cases selected')
    summary = dict(total=len(records), failed=sum(bool(row['errors']) for row in records))
    if args.candidate:
        summary['candidate_checked'] = len(records)
    if args.gfortran:
        summary['gnu_checked'] = sum(not row.get('gnu_skipped', False) for row in records)
        summary['gnu_skipped'] = sum(row.get('gnu_skipped', False) for row in records)
        summary['gnu_executed'] = sum('gnu_run' in row for row in records)
        summary['gnu_compile_only'] = sum(row['case']['baseline'] == 'compile' for row in records)
        summary['gnu_rejections'] = sum(row['case']['baseline'] == 'reject' for row in records)
        summary['specification_only'] = sum('oracle' in row['case'] for row in records)
    result = dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  summary=summary, records=records, platform=platform.platform(),
                  python_version=platform.python_version(),
                  manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                  source_sha256={row['case']['source']: hashlib.sha256((ROOT/row['case']['source']).read_bytes()).hexdigest()
                                 for row in records})
    if args.gfortran:
        result['gfortran_version'] = execute([args.gfortran, '--version'])
    if args.candidate:
        result['candidate_version'] = execute([args.candidate, '--version'])
        result['candidate_sha256'] = initial_candidate_hash
        try:
            final_hash = hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
        except OSError:
            final_hash = None
        result['candidate_final_sha256'] = final_hash
        if final_hash != initial_candidate_hash:
            result['candidate_changed_during_run'] = True
            summary['failed'] += 1
            print('FAIL: candidate executable changed during verification')
    (ROOT/args.result).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(summary, indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
