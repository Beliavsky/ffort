#!/usr/bin/env python3
"""Generic specification-call rejection and unaffected body-call regressions."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
ROOT = Path(__file__).resolve().parent


def run(args, cwd=None):
    proc = subprocess.run([str(x) for x in args], cwd=cwd, text=True,
                          capture_output=True, timeout=30, stdin=subprocess.DEVNULL)
    return dict(status=proc.returncode, stdout=proc.stdout, stderr=proc.stderr)


def clean_check(result):
    return result == dict(status=0, stdout='', stderr='')


def clean_rejection(result, diagnostic):
    return (result['status'] == 1 and result['stdout'] == ''
            and diagnostic in result['stderr']
            and 'Backtrace' not in result['stderr']
            and 'Fortran runtime error' not in result['stderr'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', default='gfortran')
    parser.add_argument('--result', type=Path, default=ROOT/'results.json')
    args = parser.parse_args()
    args.candidate = args.candidate.resolve()
    results = []
    with tempfile.TemporaryDirectory(prefix='generic-spec-guard-') as temp:
        temp = Path(temp)
        for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
            source = ROOT/'cases'/(case['name']+'.f90')
            assert hashlib.sha256(source.read_bytes()).hexdigest() == case['sha256']
            compiled = run([args.gfortran, '-std=f2018', '-pedantic-errors', '-fcheck=all',
                            '-ffpe-trap=invalid,zero,overflow', source, '-o', temp/'oracle'], temp)
            oracle = run([temp/'oracle'], temp) if compiled['status'] == 0 else None
            check = run([args.candidate, '--check', source])
            actual = run([args.candidate, source])
            if case['expected'] == 'gnu_compile_rejection':
                ok = compiled['status'] != 0 and bool(compiled['stderr']) and oracle is None
            else:
                ok = oracle is not None and oracle['status'] == 0 and not oracle['stderr']
                ok = ok and oracle['stdout'].split() == case['output'].split()
            if case['expected'] in ('boundary', 'gnu_compile_rejection'):
                ok = ok and clean_rejection(check, case['diagnostic'])
                ok = ok and clean_rejection(actual, case['diagnostic'])
            else:
                ok = ok and clean_check(check) and actual['status'] == 0 and not actual['stderr']
                ok = ok and actual['stdout'].split() == oracle['stdout'].split()
            results.append(dict(name=case['name'], expected=case['expected'], passed=bool(ok),
                                compile=compiled, oracle=oracle, check=check, actual=actual))
            print(('PASS: ' if ok else 'FAIL: ')+case['name'], flush=True)
    result = dict(candidate_sha256=hashlib.sha256(args.candidate.read_bytes()).hexdigest(),
                  total=len(results), failed=sum(not x['passed'] for x in results), cases=results)
    args.result.write_text(json.dumps(result, indent=2)+'\n')
    print('Total:', result['total'], 'failed:', result['failed'])
    return result['failed'] != 0


if __name__ == '__main__':
    raise SystemExit(main())
