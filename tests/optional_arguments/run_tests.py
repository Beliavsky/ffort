#!/usr/bin/env python3
"""GNU differential tests plus separate OPTIONAL/PRESENT safety boundaries.

Runtime-invalid fixtures are compiled by GNU but deliberately never executed.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def run(command, cwd=None):
    try:
        result = subprocess.run([str(arg) for arg in command], cwd=cwd,
                                text=True, capture_output=True, timeout=30)
        return dict(status=result.returncode, stdout=result.stdout, stderr=result.stderr)
    except (OSError, subprocess.TimeoutExpired) as error:
        return dict(status=None, stdout='', stderr=str(error))


def equal(actual, expected):
    actual = actual.lower().replace('d', 'e').split()
    expected = expected.lower().replace('d', 'e').split()
    if len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        try:
            if not math.isclose(float(got), float(want), rel_tol=1e-10, abs_tol=1e-12):
                return False
        except ValueError:
            if got != want:
                return False
    return True


def verify_provenance():
    harness = (ROOT / 'exact_utility_bodies.f90').read_text()
    for item in json.loads((ROOT / 'utility_provenance.json').read_text()):
        body = (ROOT.parent.parent / item['source']).read_text()
        if hashlib.sha256(body.encode()).hexdigest() != item['normalized_sha256']:
            raise SystemExit('Utility source hash mismatch: ' + item['name'])
        if harness.count(body) != 1:
            raise SystemExit('Utility body differs from original: ' + item['name'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', default='gfortran')
    parser.add_argument('--result', default='results.json', type=Path)
    args = parser.parse_args()
    args.candidate = args.candidate.resolve()
    verify_provenance()
    cases = json.loads((ROOT / 'manifest.json').read_text())
    results = []
    with tempfile.TemporaryDirectory(prefix='optional-arguments-') as temporary:
        temporary = Path(temporary)
        for case in cases:
            source = ROOT / (case['name'] + '.f90')
            executable = temporary / 'oracle'
            compiled = run([args.gfortran, '-std=f2018', '-fcheck=all', source,
                            '-o', executable], temporary)
            checked = run([args.candidate, '--check', source])
            result = run([args.candidate, source])
            oracle = None
            if case['kind'] == 'valid':
                if compiled['status'] == 0:
                    oracle = run([executable], temporary)
                passed = (compiled['status'] == 0 and oracle['status'] == 0
                          and checked['status'] == 0 and not checked['stdout']
                          and not checked['stderr'] and result['status'] == 0
                          and not result['stderr'] and equal(result['stdout'], oracle['stdout']))
            elif case['kind'] == 'runtime':
                passed = (compiled['status'] == 0 and checked['status'] == 0
                          and not checked['stdout'] and not checked['stderr']
                          and result['status'] == 2 and not result['stdout']
                          and case['diagnostic_contains'] in result['stderr'])
            else:
                passed = (checked['status'] == 1 and result['status'] == 1
                          and not checked['stdout'] and not result['stdout']
                          and case['diagnostic_contains'] in checked['stderr']
                          and case['diagnostic_contains'] in result['stderr']
                          and compiled['status'] == case['gnu_compile_expected'])
            results.append(dict(name=case['name'], passed=passed, expected=case['kind'],
                                gfortran=compiled, oracle=oracle, check=checked, candidate=result))
            print(('PASS' if passed else 'FAIL') + ': ' + case['name'], flush=True)
    report = dict(candidate_sha256=hashlib.sha256(args.candidate.read_bytes()).hexdigest(),
                  candidate_version=run([args.candidate, '--version'])['stdout'].strip(),
                  gfortran_version=run([args.gfortran, '--version'])['stdout'].splitlines()[0],
                  total=len(results), failed=sum(not case['passed'] for case in results), cases=results)
    output = args.result if args.result.is_absolute() else ROOT / args.result
    output.write_text(json.dumps(report, indent=2) + '\n')
    print('Total:', report['total'], 'failed:', report['failed'])
    return bool(report['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
