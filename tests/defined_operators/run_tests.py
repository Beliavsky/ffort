#!/usr/bin/env python3
"""Run defined-operator CLI and GNU differential checks in isolated directories."""
from pathlib import Path
import argparse
import json
import subprocess
import tempfile
import hashlib
ROOT=Path(__file__).resolve().parent

def run(args,cwd):
    p=subprocess.run([str(x) for x in args],cwd=cwd,text=True,capture_output=True,timeout=30)
    return dict(code=p.returncode,out=p.stdout,err=p.stderr)

def same(a,b):
    aa=a.split();bb=b.split()
    if len(aa)!=len(bb):return False
    for x,y in zip(aa,bb):
        try:
            if abs(float(x)-float(y))>1e-8:return False
        except ValueError:
            if x!=y:return False
    return True

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path)
    ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',default='results.json')
    a=ap.parse_args();exe=a.candidate.resolve();results=[]
    for c in json.loads((ROOT/'cases.json').read_text()):
        with tempfile.TemporaryDirectory(prefix='operator-oracle-') as tmp:
            src=ROOT/c['file'];errors=[]
            check=run([exe,'--check',src],tmp);actual=run([exe,src],tmp)
            compile=run([a.gfortran,'-std=f2018','-Wall','-Wextra','-fcheck=all',src,'-o',Path(tmp)/'oracle'],tmp)
            oracle=None
            if c['category']=='success':
                if compile['code']!=0:errors.append('GNU compilation failed')
                else:
                    oracle=run([Path(tmp)/'oracle'],tmp)
                    if oracle['code'] or not same(oracle['out'],c['expected_stdout']):errors.append('GNU expectation mismatch')
                if check['code'] or actual['code']:errors.append('candidate rejected valid source')
                if not same(actual['out'],c['expected_stdout']):errors.append('candidate output mismatch')
                if oracle and not same(actual['out'],oracle['out']):errors.append('GNU differential mismatch')
            else:
                if check['code']!=1 or actual['code']!=1:errors.append('reject exit mismatch')
                if actual['out'].strip():errors.append('output before source rejection')
                if c['diagnostic'] not in actual['err']:errors.append('reject diagnostic mismatch')
                if c['gnu_valid']!=(compile['code']==0):errors.append('GNU validity mismatch')
            if check['out'].strip():errors.append('check stdout leak')
            results.append(dict(**c,source_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),check=check,actual=actual,gnu_compile=compile,gnu=oracle,errors=errors))
            print(('PASS' if not errors else 'FAIL')+': '+c['name']+(' '+str(errors) if errors else ''))
    result=dict(candidate_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(),passed=sum(not r['errors'] for r in results),total=len(results),cases=results)
    (ROOT/a.result).write_text(json.dumps(result,indent=2)+'\n')
    return 0 if result['passed']==result['total'] else 1
if __name__=='__main__':raise SystemExit(main())
