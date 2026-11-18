#!/usr/bin/env python3
"""No-argument RANDOM_SEED: syntax/GNU contracts separate from interpreter seed policy."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def run(argv, cwd):
    try:
        p = subprocess.run([str(a) for a in argv], cwd=cwd, input='', text=True,
                           capture_output=True, timeout=20)
        return dict(code=p.returncode, out=p.stdout, err=p.stderr)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return dict(code=None, out='', err=str(exc))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--gfortran', required=True)
    parser.add_argument('--result', default='results.json')
    args = parser.parse_args()
    cases = json.loads((ROOT / 'manifest.json').read_text())['cases']
    records = []
    with tempfile.TemporaryDirectory(prefix='random-seed-empty-') as tmp:
        temp = Path(tmp)
        candidate = temp / 'candidate'
        shutil.copy2(Path(args.candidate).resolve(), candidate)
        compiler = str(Path(args.gfortran).resolve())
        for case in cases:
            source = ROOT / case['source']
            check = run([candidate, '--check', source], temp)
            actual = run([candidate, source], temp)
            expected_code = 0 if case['category'] == 'success' else 1
            errors = []
            if check['code'] != expected_code or actual['code'] != expected_code:
                errors.append('candidate exit status')
            if check['out'].strip():
                errors.append('check stdout leak')
            if actual['out'].split() != case['expected_stdout'].split():
                errors.append('candidate output differs or leaked before rejection')
            for result in (check, actual):
                if (expected_code == 0 and result['err'].strip()) or (expected_code and not result['err'].strip()):
                    errors.append('candidate diagnostic contract')
            row = dict(case=case, check=check, run=actual, errors=errors,
                       source_sha256=hashlib.sha256(source.read_bytes()).hexdigest())
            if case['gnu'] != 'skip':
                oracle = temp / 'oracle'
                compiled = run([compiler, '-std=f2018', '-pedantic-errors', '-fcheck=all',
                                '-O0', source, '-o', oracle], temp)
                row['gnu_compile'] = compiled
                if case['gnu'] == 'reject':
                    if compiled['code'] != 1:
                        errors.append('GNU did not cleanly reject')
                elif compiled['code'] != 0:
                    errors.append('GNU compile failed')
                elif case['gnu'] == 'run':
                    result = run([oracle], temp)
                    row['gnu_run'] = result
                    if result['code'] != 0 or result['out'].split() != case['expected_stdout'].split():
                        errors.append('GNU execution or expected output')
            if case.get('repeat'):
                repeated = run([candidate, source], temp)
                row['repeat'] = repeated
                if repeated != actual:
                    errors.append('interpreter repeatability')
            records.append(row)
            print(case['name'] + ': ' + ('FAIL: ' + ', '.join(errors) if errors else 'PASS'), flush=True)
        digest = hashlib.sha256(candidate.read_bytes()).hexdigest()
    summary = dict(total=len(records), failed=sum(bool(r['errors']) for r in records),
                   gnu_executed=sum('gnu_run' in r for r in records),
                   gnu_compile_only=sum(r['case']['gnu'] == 'compile' for r in records),
                   gnu_rejections=sum(r['case']['gnu'] == 'reject' for r in records),
                   interpreter_policy_only=sum(r['case']['gnu'] == 'skip' for r in records))
    result_path = Path(args.result)
    if not result_path.is_absolute():
        result_path = ROOT / result_path
    result_path.write_text(json.dumps(dict(summary=summary, records=records, candidate_sha256=digest,
        limits='GNU validates syntax and non-random outputs only. Deterministic seed replay is interpreter policy, not GNU sequence equality.'), indent=2) + '\n')
    print(json.dumps(summary, indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
