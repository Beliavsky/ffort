#!/usr/bin/env python3
"""Compare 272 REAL32/REAL64/mixed-kind outputs to GNU Fortran byte for byte.

The checked-in source uses eight fixed, positive operand sets and 34 expressions
per set. Each operation is evaluated through mutable variables to avoid making
this a constant-folding-only test. All outputs use an explicit ES format. This
runner executes the full candidate, including its FortFront cross-check.
"""
from pathlib import Path
import argparse
import json
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', default='gfortran')
    parser.add_argument('--result', type=Path)
    args = parser.parse_args()
    candidate = args.candidate.resolve()
    source = ROOT / 'math_matrix.f90'
    outcomes = {}
    with tempfile.TemporaryDirectory(prefix='fortfront-math-matrix-') as directory:
        directory = Path(directory)
        oracle = directory / 'oracle.exe'
        compile_result = subprocess.run(
            [args.gfortran, '-std=f2018', '-pedantic-errors', '-fcheck=all', str(source), '-o', str(oracle)],
            cwd=directory, text=True, capture_output=True, timeout=120)
        outcomes['gnu_compile_status'] = compile_result.returncode
        if compile_result.returncode:
            raise SystemExit('GNU Fortran matrix compilation failed:\n' + compile_result.stderr)
        reference = subprocess.run([str(oracle)], cwd=directory, text=True, capture_output=True, timeout=30)
        checked = subprocess.run([str(candidate), '--check', str(source)], cwd=directory,
                                 text=True, capture_output=True, timeout=30)
        actual = subprocess.run([str(candidate), str(source)], cwd=directory,
                                text=True, capture_output=True, timeout=30)
        outcomes.update(
            gnu_status=reference.returncode, candidate_check_status=checked.returncode,
            candidate_check_stdout=checked.stdout, candidate_check_stderr=checked.stderr,
            candidate_status=actual.returncode, candidate_stderr=actual.stderr,
            value_count=len(reference.stdout.splitlines()), exact_stdout_match=actual.stdout == reference.stdout,
            expected_stdout=reference.stdout, actual_stdout=actual.stdout,
        )
        outcomes['pass'] = (
            reference.returncode == 0 and checked.returncode == 0 and not checked.stdout and
            not checked.stderr and actual.returncode == 0 and not actual.stderr and
            len(reference.stdout.splitlines()) == 272 and actual.stdout == reference.stdout
        )
        if args.result:
            args.result.resolve().write_text(json.dumps(outcomes, indent=2) + '\n', encoding='utf-8')
        if not outcomes['pass']:
            raise SystemExit('FAIL: REAL32/REAL64 matrix differs from GNU Fortran.\n' +
                             checked.stderr + actual.stderr)
    print('PASS: 272 REAL32, REAL64 and mixed-kind outputs exactly match GNU Fortran')


if __name__ == '__main__':
    main()
