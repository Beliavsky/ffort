#!/usr/bin/env python3
"""Run the module USE / chained-PARAMETER boundary against GNU Fortran."""
import argparse, hashlib, json, math, re, subprocess, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parent

def run(args, cwd=None):
    p = subprocess.run([str(x) for x in args], cwd=cwd, text=True, capture_output=True, timeout=30)
    return dict(status=p.returncode, stdout=p.stdout, stderr=p.stderr)

def equal(left, right):
    left, right = left.split(), right.split()
    if len(left) != len(right): return False
    for a,b in zip(left,right):
        if re.fullmatch(r'[+-]?\d+',a) and re.fullmatch(r'[+-]?\d+',b):
            if int(a) != int(b): return False
        else:
            try:
                if not math.isclose(float(a.replace('D','E').replace('d','e')), float(b.replace('D','E').replace('d','e')), rel_tol=1e-12, abs_tol=1e-14): return False
            except ValueError:
                if a != b: return False
    return True

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--candidate',type=Path,required=True)
    parser.add_argument('--gfortran',default='gfortran');parser.add_argument('--result',type=Path,default=ROOT/'results.json')
    args=parser.parse_args(); candidate=args.candidate.resolve();results=[]
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        # A clean working directory per oracle is essential: stale .mod files
        # can make intentionally forward/missing module imports appear valid.
        with tempfile.TemporaryDirectory(prefix='module-use-oracle-') as tmp:
            src=ROOT/(case['name']+'.f90');exe=Path(tmp)/'oracle'
            gnu=run([args.gfortran,'-std=f2018','-fcheck=all',src,'-o',exe],tmp)
            oracle=run([exe],tmp) if gnu['status']==0 else None
            check=run([candidate,'--check',src]);out=run([candidate,src]);expected=case.get('expected')
            if expected is not None:
                passed=gnu['status']==0 and oracle['status']==0 and check['status']==0 and out['status']==0
                passed=passed and not check['stdout'] and not check['stderr'] and not out['stderr']
                passed=passed and equal(out['stdout'],expected) and equal(out['stdout'],oracle['stdout'])
            else:
                passed=check['status']==1 and out['status']==1 and not check['stdout'] and not out['stdout']
                fragment=case.get('diagnostic_contains')
                if fragment: passed=passed and fragment in check['stderr'] and fragment in out['stderr']
                passed=passed and ((gnu['status']!=0) if case.get('gnu_invalid') else (gnu['status']==0))
            results.append(dict(name=case['name'],passed=passed,check=check,candidate=out,gfortran=gnu,oracle=oracle))
            print(('PASS ' if passed else 'FAIL ')+case['name'],flush=True)
    report=dict(total=len(results),failed=sum(not r['passed'] for r in results),candidate_sha256=hashlib.sha256(candidate.read_bytes()).hexdigest(),gfortran=run([args.gfortran,'--version'])['stdout'].splitlines()[0],cases=results)
    args.result.write_text(json.dumps(report,indent=2)+'\n');print('Total',report['total'],'failed',report['failed'])
    return bool(report['failed'])
if __name__=='__main__':raise SystemExit(main())
