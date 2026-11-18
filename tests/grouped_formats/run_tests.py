#!/usr/bin/env python3
"""Bounded grouped formats: independent expectations, GNU differential and negatives."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def run(args, cwd):
    result = subprocess.run([str(arg) for arg in args], cwd=cwd, capture_output=True, timeout=25)
    return {'status': result.returncode, 'stdout': result.stdout.decode(), 'stderr': result.stderr.decode()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', default='gfortran')
    parser.add_argument('--result', type=Path, default=ROOT/'results.json')
    args = parser.parse_args()
    candidate = args.candidate.resolve()
    rows = []
    with tempfile.TemporaryDirectory(prefix='grouped-formats-') as tmp:
        for case in json.loads((ROOT/'manifest.json').read_text()):
            path = ROOT/'cases'/(case['name']+'.f90')
            check = run([candidate, '--check', path], tmp)
            result = run([candidate, path], tmp)
            row = {**case, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                   'check': check, 'candidate': result}
            if case['kind'] == 'pass':
                exe = Path(tmp)/'reference'
                compiled = run([args.gfortran, '-std=f2018', '-pedantic-errors', '-fcheck=all',
                                path, '-o', exe], tmp)
                reference = run([exe], tmp) if compiled['status'] == 0 else compiled
                row.update(reference_compile=compiled, reference=reference)
                ok = (check['status'] == 0 and not check['stdout'] and result['status'] == 0
                      and compiled['status'] == 0 and reference['status'] == 0
                      and result['stdout'] == case['stdout'] == reference['stdout'])
            else:
                status = 1 if case['kind'] == 'reject' else 2
                ok = (check['status'] == (1 if status == 1 else 0) and not check['stdout']
                      and result['status'] == status and not result['stdout']
                      and case['diagnostic'].lower() in result['stderr'].lower())
            row['pass'] = ok
            rows.append(row)
            print(('PASS' if ok else 'FAIL')+': '+case['name'], flush=True)
            if not ok:
                print('  '+repr(result)[:1000], flush=True)
                if 'reference' in row:
                    print('  GNU '+repr(row['reference'])[:1000], flush=True)
    args.result.write_text(json.dumps({
        'candidate_sha256': hashlib.sha256(candidate.read_bytes()).hexdigest(),
        'passed': sum(row['pass'] for row in rows),
        'failed': sum(not row['pass'] for row in rows),
        'total': len(rows), 'cases': rows}, indent=2)+'\n')
    raise SystemExit(0 if all(row['pass'] for row in rows) else 1)


if __name__ == '__main__':
    main()
