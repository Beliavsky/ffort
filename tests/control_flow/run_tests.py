#!/usr/bin/env python3
"""Counted-DO/ELSE IF differential, rejection, and runtime safety contracts."""
import argparse,hashlib,json,math,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def run(args,cwd=None):
 p=subprocess.run([str(x) for x in args],cwd=cwd,text=True,capture_output=True,timeout=30)
 return {'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr}

def equivalent(a,b):
 aa=a.lower().replace('d','e').split();bb=b.lower().replace('d','e').split()
 if len(aa)!=len(bb):return False
 for x,y in zip(aa,bb):
  if re.fullmatch(r'[+-]?\d+',x) and re.fullmatch(r'[+-]?\d+',y):
   if int(x)!=int(y):return False
  else:
   try:
    if not math.isclose(float(x),float(y),rel_tol=1e-12,abs_tol=1e-14):return False
   except ValueError:
    if x!=y:return False
 return True

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',default='results.json');a=ap.parse_args();a.candidate=a.candidate.resolve()
 results=[]
 with tempfile.TemporaryDirectory(prefix='control-flow-') as temp:
  temp=Path(temp)
  for c in json.loads((ROOT/'manifest.json').read_text())['cases']:
   src=ROOT/(c['name']+'.f90');check=run([a.candidate,'--check',src]);actual=run([a.candidate,src]);expected=c['expected'];oracle=None;compile=None
   if expected=='run':
    compile=run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all',src,'-o',temp/'oracle'],temp)
    if compile['status']==0:oracle=run([temp/'oracle'],temp)
    ok=oracle is not None and oracle['status']==0 and check['status']==0 and actual['status']==0 and not actual['stderr'] and equivalent(actual['stdout'],oracle['stdout'])
   elif expected=='policy':ok=check['status']==0 and actual['status']==0 and not actual['stderr'] and equivalent(actual['stdout'],c['output'])
   elif expected=='reject':ok=check['status']==1 and actual['status']==1 and not actual['stdout'] and not check['stdout'] and bool(actual['stderr'])
   else:ok=check['status']==0 and actual['status']==2 and not actual['stdout'] and bool(actual['stderr'])
   results.append({'name':c['name'],'expected':expected,'pass':ok,'check':check,'actual':actual,'compile':compile,'oracle':oracle})
   print(('PASS' if ok else 'FAIL')+': '+c['name'],flush=True)
 result={'candidate_sha256':hashlib.sha256(a.candidate.read_bytes()).hexdigest(),'total':len(results),'failed':sum(not c['pass'] for c in results),'cases':results};out=Path(a.result);out=out if out.is_absolute() else ROOT/out;out.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
