#!/usr/bin/env python3
"""Contextual PROCEDURE identifier differential and rejection contracts."""
import argparse,hashlib,json,math,re,subprocess,tempfile
from pathlib import Path
from decimal import Decimal
ROOT=Path(__file__).resolve().parent
from check_provenance import check as check_provenance

def run(args,cwd=None):
 p=subprocess.run([str(x) for x in args],cwd=cwd,text=True,capture_output=True,timeout=30)
 return {'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr}

INTEGER = re.compile(r'[+-]?\d+')
REAL = re.compile(r'[+-]?(?:(?:\d+\.\d*|\.\d+)(?:[eEdD][+-]?\d+)?|\d+[eEdD][+-]?\d+)')
NONFINITE = re.compile(r'[+-]?(?:inf(?:inity)?|nan(?:\([^)]*\))?)', re.IGNORECASE)

def equivalent(a,b):
 # Ignore list-directed whitespace, but preserve every nonnumeric token exactly.
 aa=a.split();bb=b.split()
 if len(aa)!=len(bb):return False
 for x,y in zip(aa,bb):
  if NONFINITE.fullmatch(x) or NONFINITE.fullmatch(y):return False
  xi=bool(INTEGER.fullmatch(x));yi=bool(INTEGER.fullmatch(y))
  xr=bool(REAL.fullmatch(x));yr=bool(REAL.fullmatch(y))
  if xi and yi:
   if int(x)!=int(y):return False
  elif (xi or xr) and (yi or yr):
   # D/E normalization is confined to complete numeric tokens.
   nx=x.replace('D','e').replace('d','e');ny=y.replace('D','e').replace('d','e')
   fx=float(nx);fy=float(ny)
   if not math.isfinite(fx) or not math.isfinite(fy):return False
   if xi or yi:
    # Never round an integer through binary64, even opposite a real token.
    if Decimal(nx)!=Decimal(ny):return False
   elif not math.isclose(fx,fy,rel_tol=1e-12,abs_tol=1e-14):return False
  elif x!=y:return False
 return True

def successful_check(result):
 return result['status']==0 and not result['stdout'] and not result['stderr']

def main():
 check_provenance()
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',default='results.json');a=ap.parse_args();a.candidate=a.candidate.resolve()
 results=[]
 with tempfile.TemporaryDirectory(prefix='procedure-name-') as temp:
  temp=Path(temp)
  for c in json.loads((ROOT/'manifest.json').read_text())['cases']:
   src=ROOT/(c['name']+'.f90');check=run([a.candidate,'--check',src]);actual=run([a.candidate,src]);expected=c['expected'];oracle=None;compile=None
   if expected in ('run','boundary'):
    compile=run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow',src,'-o',temp/'oracle'],temp)
    if compile['status']==0:oracle=run([temp/'oracle'],temp)
    ok=oracle is not None and oracle['status']==0 and successful_check(check) and actual['status']==0 and actual['stderr']==c.get('stderr_exact','') and equivalent(actual['stdout'],oracle['stdout'])
    if expected=='boundary':ok=compile['status']==0 and oracle is not None and oracle['status']==0 and check['status']==1 and actual['status']==1 and not actual['stdout'] and not check['stdout'] and bool(actual['stderr']) and equivalent(oracle['stdout'],c['output'])
   elif expected=='policy':ok=successful_check(check) and actual['status']==0 and not actual['stderr'] and equivalent(actual['stdout'],c['output'])
   elif expected=='reject':ok=check['status']==1 and actual['status']==1 and not actual['stdout'] and not check['stdout'] and bool(actual['stderr'])
   else:ok=successful_check(check) and actual['status']==2 and not actual['stdout'] and bool(actual['stderr'])
   if expected=='run' and 'output' in c:ok=ok and equivalent(actual['stdout'],c['output'])
   if c.get('diagnostic_contains'):ok=ok and c['diagnostic_contains'].lower() in actual['stderr'].lower()
   results.append({'name':c['name'],'expected':expected,'pass':ok,'check':check,'actual':actual,'compile':compile,'oracle':oracle,'reason':c.get('reason')})
   print(('PASS' if ok else 'FAIL')+': '+c['name'],flush=True)
 result={'candidate_sha256':hashlib.sha256(a.candidate.read_bytes()).hexdigest(),'total':len(results),'failed':sum(not c['pass'] for c in results),'cases':results};out=Path(a.result);out=out if out.is_absolute() else ROOT/out;out.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
