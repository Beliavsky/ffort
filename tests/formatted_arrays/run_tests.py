#!/usr/bin/env python3
"""Bounded formatted-array differential and fail-closed tests (no shell)."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent

def run(args):
    p = subprocess.run([str(a) for a in args], capture_output=True, timeout=25)
    return {'status': p.returncode, 'stdout': p.stdout.decode(), 'stderr': p.stderr.decode()}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', default='gfortran')
    parser.add_argument('--result', type=Path, default=ROOT/'results.json')
    args = parser.parse_args()
    rows=[]
    with tempfile.TemporaryDirectory(prefix='formatted-arrays-') as tmp:
        for case in json.loads((ROOT/'manifest.json').read_text()):
            path = ROOT/'cases'/(case['name']+'.f90')
            check = run([args.candidate.resolve(), '--check', path])
            result = run([args.candidate.resolve(), path])
            row = {**case, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'check': check, 'candidate':result}
            if case['kind'] in ('pass', 'upstream'):
                exe=Path(tmp)/'reference'
                compile = run([args.gfortran, '-std=f2018', '-fcheck=all', path, '-o', exe])
                row['reference_compile']=compile
                reference=run([exe]) if compile['status']==0 else compile
                row['reference']=reference
                observed=result['stdout']; expected=reference['stdout']
                if case['kind']=='upstream':
                    # GNU's list-directed field width is processor-dependent.
                    # Compare every formatted/empty record byte-for-byte, then
                    # compare only the final list-directed integer as a token.
                    observed=observed.splitlines(); expected=expected.splitlines()
                    matched=observed[:-1]==expected[:-1] and observed[-1].split()==expected[-1].split()
                else:
                    matched=observed==expected
                ok=check['status']==0 and not check['stdout'] and result['status']==0 and reference['status']==0 and matched
            else:
                expected=1 if case['kind']=='reject' else 2
                ok=result['status']==expected and not result['stdout'] and case['diagnostic'].lower() in result['stderr'].lower()
                ok=ok and check['status']==(1 if case['kind']=='reject' else 0) and not check['stdout']
            row['pass']=ok;rows.append(row)
            print(('PASS' if ok else 'FAIL')+': '+case['name'],flush=True)
            if not ok: print('  '+result['stderr'][:500]+' observed='+repr(result['stdout'][:150]),flush=True)
    args.result.write_text(json.dumps({'candidate_sha256': hashlib.sha256(args.candidate.resolve().read_bytes()).hexdigest(), 'passed':sum(r['pass'] for r in rows), 'failed':sum(not r['pass'] for r in rows),'total':len(rows),'cases':rows},indent=2)+'\n')
    raise SystemExit(0 if all(r['pass'] for r in rows) else 1)

if __name__=='__main__': main()
