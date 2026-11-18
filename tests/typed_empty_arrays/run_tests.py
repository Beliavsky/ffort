#!/usr/bin/env python3
"""Exact values (including signed zero), token text, and historical source checks."""
import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NONFINITE = re.compile(r'[+-]?(?:inf(?:inity)?|nan(?:\([^)]*\))?)\Z', re.I)
NUMBER = re.compile(r'[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eEdD][+-]?\d+)?\Z')
CRASH = re.compile(r'internal compiler error|please submit a full bug report|'
                   r'backtrace|fortran runtime error|segmentation fault|'
                   r'\bSIG(?:SEGV|ABRT|BUS|ILL|FPE|KILL|TERM)\b|'
                   r'terminated by signal|fatal signal|TIMEOUT|timed out|OSError', re.I)


def equivalent(a, b):
    a, b = a.split(), b.split()
    if len(a) != len(b):
        return False
    for x, y in zip(a, b):
        if NONFINITE.fullmatch(x) or NONFINITE.fullmatch(y):
            return False
        if NUMBER.fullmatch(x) and NUMBER.fullmatch(y):
            x = Decimal(x.replace('d', 'e').replace('D', 'E'))
            y = Decimal(y.replace('d', 'e').replace('D', 'E'))
            if not x.is_finite() or not y.is_finite() or x != y or (x == 0 and x.is_signed() != y.is_signed()):
                return False
        elif x != y:
            return False
    return True


def run(args, cwd=None):
    try:
        p = subprocess.run([str(x) for x in args], cwd=cwd, text=True,
                           capture_output=True, timeout=60, stdin=subprocess.DEVNULL)
        return dict(code=p.returncode, out=p.stdout, err=p.stderr)
    except subprocess.TimeoutExpired as exc:
        def text(value):
            return value.decode(errors='replace') if isinstance(value, bytes) else value or ''
        return dict(code=None, out=text(exc.stdout), err='TIMEOUT: ' + text(exc.stderr))
    except OSError as exc:
        return dict(code=None, out='', err='OSError: ' + str(exc))


def crashed(result):
    return (result['code'] is None or result['code'] < 0 or
            bool(CRASH.search(result['out'] + '\n' + result['err'])))


def assess(case, check, actual, gnu, oracle):
    errors = []
    for label, result in [('check', check), ('candidate', actual), ('GNU compile', gnu), ('GNU run', oracle)]:
        if result is not None and crashed(result):
            errors.append(label + ': crash, signal, timeout or unavailable engine')
    compare = (lambda x, y: x == y) if case.get('compare_mode') == 'exact' else equivalent
    if case['category'] == 'run':
        if check != dict(code=0, out='', err=''):
            errors.append('check: expected silent success')
        if actual['code'] != 0 or actual['err'] or not compare(actual['out'], case['output']):
            errors.append('candidate: output/status mismatch')
    else:
        for label, result in [('check', check), ('candidate', actual)]:
            if result['code'] != 1 or result['out'] or not result['err']:
                errors.append(label + ': expected clean rejection with exit 1')
    if case['gnu'] == 'reject':
        if gnu['code'] != 1 or not gnu['err']:
            errors.append('GNU compile: expected clean rejection with exit 1')
    elif gnu['code'] != 0:
        errors.append('GNU compile: expected success')
    if case['gnu'] == 'run':
        if oracle is None or oracle['code'] != 0 or oracle['err'] or not compare(oracle['out'], case['output']):
            errors.append('GNU run: output/status mismatch')
    if case.get('diagnostic') and case['diagnostic'] not in actual['err']:
        errors.append('candidate: missing expected diagnostic')
    return errors


def evaluate_case(case, candidate, compiler):
    src = ROOT / case.get('source', case['name'] + '.f90')
    assert hashlib.sha256(src.read_bytes()).hexdigest() == case['sha256']
    # A separate cwd per case prevents .mod/.smod or executable reuse, including
    # between an earlier success and a later expected compiler rejection.
    with tempfile.TemporaryDirectory(prefix='typed-empty-case-') as temp:
        temp = Path(temp)
        if case.get('support_sources'):
            parts = []
            for part in case['support_sources']:
                data = (ROOT / part['source']).read_bytes()
                assert hashlib.sha256(data).hexdigest() == part['sha256']
                parts.append(data)
            parts.append(src.read_bytes())
            src = temp / 'combined.f90'
            src.write_bytes(b'\n'.join(parts))
        check = run([candidate, '--check', src], temp)
        actual = run([candidate, src], temp)
        gnu = run([compiler, '-std=f2018', '-pedantic-errors', '-fcheck=all', src, '-o', temp / 'oracle'], temp)
        oracle = None
        if case['gnu'] == 'run' and gnu['code'] == 0 and not crashed(gnu):
            oracle = run([temp / 'oracle'], temp)
        errors = assess(case, check, actual, gnu, oracle)
        return dict(name=case['name'], passed=not errors, errors=errors,
                    check=check, actual=actual, gnu=gnu, oracle=oracle, cwd=str(temp))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--candidate', required=True, type=Path)
    ap.add_argument('--gfortran', default='gfortran')
    ap.add_argument('--result', type=Path, default=ROOT / 'results.json')
    args = ap.parse_args()
    candidate = args.candidate.resolve()
    results = []
    for case in json.loads((ROOT / 'manifest.json').read_text())['cases']:
        result = evaluate_case(case, candidate, args.gfortran)
        results.append(result)
        print(('PASS: ' if result['passed'] else 'FAIL: ') + case['name'], flush=True)
    report = dict(total=len(results), failed=sum(not c['passed'] for c in results),
                  candidate_sha256=hashlib.sha256(candidate.read_bytes()).hexdigest(), cases=results)
    args.result.write_text(json.dumps(report, indent=2) + '\n')
    print('Total:', report['total'], 'failed:', report['failed'])
    return report['failed'] != 0


if __name__ == '__main__':
    raise SystemExit(main())
