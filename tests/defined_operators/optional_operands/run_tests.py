#!/usr/bin/env python3
"""Verify invalid OPTIONAL operator operands, including unused interfaces."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--gfortran',default='gfortran');p.add_argument('--result',type=Path,default=ROOT/'results.json');a=p.parse_args()
rows=[]
for src in sorted(ROOT.glob('*.f90')):
    with tempfile.TemporaryDirectory(prefix='optional-operator-') as tmp:
        def run(args):
            q=subprocess.run([str(v) for v in args],cwd=tmp,text=True,capture_output=True,timeout=30)
            return dict(code=q.returncode,stdout=q.stdout,stderr=q.stderr)
        gnu=run([a.gfortran,'-std=f2018','-pedantic-errors',src,'-o',Path(tmp)/'oracle'])
        check=run([a.candidate.resolve(),'--check',src]);actual=run([a.candidate.resolve(),src])
        passed=gnu['code']!=0 and 'cannot be optional' in gnu['stderr'] and all(x['code']==1 and not x['stdout'] and 'Defined operator arguments cannot be OPTIONAL' in x['stderr'] for x in [check,actual])
        rows.append(dict(name=src.name,passed=passed,gnu=gnu,check=check,actual=actual))
        print(('PASS' if passed else 'FAIL')+': '+src.name)
a.result.write_text(json.dumps(dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(rows),passed=sum(r['passed'] for r in rows),cases=rows),indent=2)+'\n')
raise SystemExit(0 if all(r['passed'] for r in rows) else 1)
