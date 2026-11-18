#!/usr/bin/env python3
"""Independent explicit-shape dummy-bound oracles and fail-closed safety boundaries.

Uses the CLI directly; GNU Fortran is only an oracle, never an execution backend.
Compiler runs occur in fresh temporary directories to prevent stale .mod reuse.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import math
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def execute(argv, cwd=None):
    try:
        proc = subprocess.run([str(arg) for arg in argv], cwd=cwd or ROOT,
                              text=True, capture_output=True, timeout=15,
                              stdin=subprocess.DEVNULL)
        return dict(code=proc.returncode, out=proc.stdout, err=proc.stderr)
    except subprocess.TimeoutExpired as exc:
        def txt(value):
            return value.decode(errors='replace') if isinstance(value, bytes) else value or ''
        return dict(code=None, out=txt(exc.stdout), err='TIMEOUT '+txt(exc.stderr))
    except OSError as exc:
        return dict(code=None, out='', err=str(exc))


def compare(actual, expected, rel_tol=2e-6, abs_tol=1e-7, mode="tokens"):
    if mode == "lines":
        return actual.rstrip("\r\n") == expected.rstrip("\r\n")
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
        if not expected and stage['err'].strip():
            errors.append(name+': unexpected success diagnostic')
    if check['out']:
        errors.append('check stdout leak')
    if category != 'success' and result['out']:
        errors.append('rejection stdout leak')
    if not compare(result['out'], case['expected_stdout'],
                   case.get('rel_tol',2e-6),case.get('abs_tol',1e-7),case.get('compare_mode','tokens')):
        errors.append('stdout mismatch/leak')
    if case.get('diagnostic'):
        diagnostic = '\n'.join(re.sub(r'^.*?:\d+:\d+:', '', line)
                               for line in result['err'].splitlines())
        if case['diagnostic'].lower() not in diagnostic.lower():
            errors.append('missing diagnostic '+case['diagnostic'])
    return errors


def validate_case(case):
    if case['category'] not in ('success', 'runtime', 'reject'):
        raise ValueError('Unknown candidate category')
    if case['baseline'] not in ('run', 'compile', 'reject'):
        raise ValueError('Unknown GNU oracle stage')
    if case['category'] != 'success' and (case['baseline'] == 'run' or case['expected_stdout']):
        raise ValueError('Unsafe fixtures must not execute with GNU or emit stdout')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', help='Single executable path (no shell command)')
    parser.add_argument('--gfortran')
    parser.add_argument('--only', default='', help='Regular expression selecting case names')
    parser.add_argument('--result', default='results.json')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    provenance = json.loads((ROOT/'provenance.json').read_text())
    original = (ROOT.parent.parent/provenance['source']).read_bytes()
    if hashlib.sha256(original).hexdigest() != provenance['source_sha256']:
        raise SystemExit('Original utilities source provenance mismatch')
    wrapper = (ROOT/provenance['wrapper']).read_bytes()
    for entry in provenance['bodies']:
        start = original.index(entry['start_marker'].encode())
        end = original.index(entry['end_marker'].encode(), start) + len(entry['end_marker'])
        body = original[start:end]
        if (hashlib.sha256(body).hexdigest() != entry['body_sha256'] or
                len(body) != entry['body_bytes'] or body not in wrapper):
            raise SystemExit('Original '+entry['name']+' provenance mismatch')
    versions = {}
    for name, executable in [('candidate', args.candidate), ('gfortran', args.gfortran)]:
        if executable:
            versions[name] = dict(path=executable, version=execute([executable, '--version']))
    records = []
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        validate_case(case)
        if not re.search(args.only, case['name']):
            continue
        source = ROOT/case['source']
        row = dict(case=case, errors=[])
        if args.gfortran:
            with tempfile.TemporaryDirectory(prefix='explicit-dummy-oracle-') as folder:
                binary = Path(folder)/'reference'
                compiled = execute([args.gfortran, '-std=f2018', '-pedantic-errors',
                                    '-fcheck=all', '-O0', source, '-o', binary], folder)
                row['gnu_compile'] = compiled
                if case['baseline'] == 'reject':
                    if compiled['code'] != 1:
                        row['errors'].append('GNU did not cleanly reject')
                elif compiled['code'] != 0:
                    row['errors'].append('GNU compile failed')
                elif case['baseline'] == 'run':
                    ran = execute([binary], folder)
                    row['gnu_run'] = ran
                    if ran['code'] != 0 or not compare(ran['out'], case['expected_stdout'],
                            case.get('rel_tol',2e-6),case.get('abs_tol',1e-7),case.get('compare_mode','tokens')):
                        row['errors'].append('GNU oracle mismatch')
        if args.candidate:
            checked = execute([args.candidate, '--check', source])
            ran = execute([args.candidate]+case.get('args', [])+[source])
            row['check'], row['run'] = checked, ran
            row['errors'] += candidate_errors(case, checked, ran)
        status = 'FAIL '+', '.join(row['errors']) if row['errors'] else 'PASS'
        print(case['name']+': '+status, flush=True)
        records.append(row)
    if not records:
        parser.error('No cases selected')
    summary = dict(total=len(records), failed=sum(bool(row['errors']) for row in records))
    if args.candidate:
        summary['candidate_checked'] = len(records)
    if args.gfortran:
        summary['gnu_checked'] = len(records)
        summary['gnu_skipped'] = 0
        summary['gnu_executed'] = sum('gnu_run' in row for row in records)
        summary['gnu_compile_only'] = sum(row['case']['baseline'] == 'compile' for row in records)
        summary['gnu_compile_rejections'] = sum(row['case']['baseline'] == 'reject' for row in records)
    result = dict(tools=versions, compiler_flags=['-std=f2018','-pedantic-errors','-fcheck=all','-O0'], utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  summary=summary, records=records,
                  manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                  source_sha256={row['case']['source']: hashlib.sha256((ROOT/row['case']['source']).read_bytes()).hexdigest()
                                 for row in records})
    if args.candidate:
        result['candidate_sha256'] = hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
    (ROOT/args.result).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(summary, indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
