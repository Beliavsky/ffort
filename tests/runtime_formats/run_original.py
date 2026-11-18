#!/usr/bin/env python3
"""Original utility dependency closure and complete unchanged MATMUL GNU proof."""
from pathlib import Path
import argparse,json,hashlib,tempfile
from check_provenance import check
from run_tests import run,successful_check
ROOT=Path(__file__).resolve().parent
def main():
 check();ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path,required=True);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',type=Path,default=ROOT/'original-results.json');a=ap.parse_args();a.candidate=a.candidate.resolve();rows=[]
 with tempfile.TemporaryDirectory(prefix='runtime-format-original-') as tmp:
  tmp=Path(tmp)
  for name in ['original_closure','demo_matmul']:
   src=ROOT/(name+'.f90');q=run([a.candidate,'--check',src],tmp);r=run([a.candidate,src],tmp)
   flags=['-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow']
   c=run([a.gfortran,*flags,src,'-o',tmp/'oracle'],tmp);ref=None
   if c['status']==0:ref=run([tmp/'oracle'],tmp)
   ok=successful_check(q) and r['status']==0 and not r['stderr'] and ref is not None and ref['status']==0 and not ref['stderr'] and r['stdout']==ref['stdout']
   rows.append(dict(name=name,passed=bool(ok),source_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),check=q,run=r,gnu_flags=flags,compile=c,reference=ref));print(('PASS: ' if ok else 'FAIL: ')+name)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(rows),failed=sum(not x['passed'] for x in rows),cases=rows);a.result.write_text(json.dumps(result,indent=2)+'\n');return bool(result['failed'])
if __name__=='__main__':raise SystemExit(main())
