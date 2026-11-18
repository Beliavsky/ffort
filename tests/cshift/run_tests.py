#!/usr/bin/env python3
"""Bounded CSHIFT fixtures, whole upstream program and strict independent GNU oracles.

Uses the CLI directly; GNU Fortran is only an oracle, never an execution backend.
Compiler runs occur in fresh temporary directories to prevent stale .mod reuse.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
from decimal import Decimal
import re
import subprocess
import shutil
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


# CSHIFT only permutes values. Do not permit tolerance, binary64 conversion or
# underflow to hide a changed token; Decimal construction preserves every digit.
NUMBER = re.compile(r'[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eEdD][+-]?\d+)?')
NONFINITE = re.compile(r'[+-]?(?:inf(?:inity)?|s?nan\d*)', re.IGNORECASE)


def compare(actual, expected, mode="tokens"):
    if mode == "exact":
        return actual == expected
    if mode == "lines":
        return actual.rstrip("\r\n") == expected.rstrip("\r\n")
    actual, expected = actual.split(), expected.split()
    if len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        # Integer expectations require integer tokens and preserve all bits,
        # including adjacent INTEGER(8) values beyond binary64's precision.
        if re.fullmatch(r'[+-]?\d+', want):
            if (not re.fullmatch(r'[+-]?\d+', got) or int(got) != int(want) or
                    (int(want) == 0 and got.startswith('-') != want.startswith('-'))):
                return False
            continue
        if NUMBER.fullmatch(want):
            if not NUMBER.fullmatch(got):
                return False
            a = Decimal(got.replace('D', 'E').replace('d', 'e'))
            b = Decimal(want.replace('D', 'E').replace('d', 'e'))
            if a != b or (a.is_zero() and a.is_signed() != b.is_signed()):
                return False
        elif NONFINITE.fullmatch(got) or NONFINITE.fullmatch(want) or got != want:
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
    if category != 'success' and result['out'] != case.get('completed_stdout', ''):
        errors.append('rejection stdout leak')
    if not compare(result['out'], case.get('completed_stdout', '')+case['expected_stdout'],
                   mode=case.get('compare_mode','tokens')):
        errors.append('stdout mismatch/leak')
    if case.get('diagnostic'):
        diagnostic = '\n'.join(re.sub(r'^.*?:\d+:\d+:', '', line)
                               for line in result['err'].splitlines())
        if case['diagnostic'].lower() not in diagnostic.lower():
            errors.append('missing diagnostic '+case['diagnostic'])
    return errors


def check_original():
    proof = json.loads((ROOT/'manifest.json').read_text())['original']
    source = (ROOT/proof['local_file']).read_bytes()
    if hashlib.sha256(source).hexdigest() != proof['sha256'] or len(source) != proof['bytes']:
        raise ValueError('Original complete M_intrinsics CSHIFT example changed')
    if proof['altered'] is not False:
        raise ValueError('Original program must be unaltered')
    return proof


def validate_case(case):
    if 'rel_tol' in case or 'abs_tol' in case:
        raise ValueError('CSHIFT output comparisons do not allow numeric tolerances')
    if case['category'] not in ('success', 'runtime', 'reject'):
        raise ValueError('Unknown candidate category')
    if case['baseline'] not in ('run', 'compile', 'reject'):
        raise ValueError('Unknown GNU oracle stage')
    if case.get('completed_stdout') and (case['category'] != 'runtime' or case['baseline'] != 'compile'):
        raise ValueError('Completed-record prefix applies only to compile-only runtime fixtures')
    if case['category'] != 'success' and (case['baseline'] == 'run' or case['expected_stdout']):
        raise ValueError('Unsafe fixtures must not execute with GNU or emit stdout')
    source = Path(case['source'])
    if source.is_absolute() or '..' in source.parts or source.suffix != '.f90':
        raise ValueError('Fixture source must be a local Fortran file')


def main():
    original_provenance = check_original()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', help='Single executable path (no shell command)')
    parser.add_argument('--gfortran')
    parser.add_argument('--only', default='', help='Regular expression selecting case names')
    parser.add_argument('--result', default='results.json')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    versions = {}
    for name, executable in [('candidate', args.candidate), ('gfortran', args.gfortran)]:
        if executable:
            resolved = shutil.which(executable) or executable
            versions[name] = dict(path=executable, resolved_path=resolved,
                                  version=execute([executable, '--version']),
                                  sha256=hashlib.sha256(Path(resolved).read_bytes()).hexdigest())
    records = []
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        validate_case(case)
        if not re.search(args.only, case['name']):
            continue
        source = ROOT/case['source']
        row = dict(case=case, errors=[])
        if args.gfortran:
            with tempfile.TemporaryDirectory(prefix='cshift-oracle-') as folder:
                binary = Path(folder)/'reference'
                compiled = execute([args.gfortran, '-std=f2018', '-pedantic-errors',
                                    '-fcheck=all', '-O0', source, '-o', binary], folder)
                row['gnu_compile'] = compiled
                if case['baseline'] == 'reject':
                    if compiled['code'] != 1 or not compiled['err'].strip():
                        row['errors'].append('GNU did not cleanly reject with diagnostic')
                elif compiled['code'] != 0:
                    row['errors'].append('GNU compile failed')
                elif case['baseline'] == 'run':
                    ran = execute([binary], folder)
                    row['gnu_run'] = ran
                    if ran['code'] != 0 or ran['err'].strip() or not compare(
                            ran['out'], case['expected_stdout'], mode=case.get('compare_mode','tokens')):
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
        summary['gnu_checked'] = sum(not row.get('gnu_skipped', False) for row in records)
        summary['gnu_skipped'] = sum(row.get('gnu_skipped', False) for row in records)
        summary['gnu_executed'] = sum('gnu_run' in row for row in records)
        summary['gnu_compile_only'] = sum(row['case']['baseline'] == 'compile' for row in records)
        summary['gnu_compile_rejections'] = sum(row['case']['baseline'] == 'reject' for row in records)
    result = dict(original=original_provenance, tools=versions, compiler_flags=['-std=f2018','-pedantic-errors','-fcheck=all','-O0'], utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  summary=summary, records=records,
                  manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                  source_sha256={row['case']['source']: hashlib.sha256((ROOT/row['case']['source']).read_bytes()).hexdigest()
                                 for row in records})
    if args.candidate:
        result['candidate_sha256'] = versions['candidate']['sha256']
    (ROOT/args.result).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(summary, indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
