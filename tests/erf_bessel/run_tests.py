#!/usr/bin/env python3
"""ERF/Bessel bounded finite contracts."""
import argparse,hashlib,json,re,subprocess,tempfile
from pathlib import Path
from decimal import Decimal,localcontext,MAX_EMAX,MIN_EMIN,InvalidOperation
ROOT=Path(__file__).resolve().parent
from check_provenance import check as check_provenance

def run(args,cwd=None):
 p=subprocess.run([str(x) for x in args],cwd=cwd,text=True,capture_output=True,timeout=30)
 return {'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr}

INTEGER = re.compile(r'[+-]?\d+')
REAL = re.compile(r'[+-]?(?:(?:\d+\.\d*|\.\d+)(?:[eEdD][+-]?\d+)?|\d+[eEdD][+-]?\d+)')
NONFINITE = re.compile(r'[+-]?(?:inf(?:inity)?|nan(?:\([^)]*\))?)', re.IGNORECASE)

# Exact round-to-nearest overflow threshold for binary64. Decimal output
# just above HUGE can still round to a finite value; the midpoint itself cannot.
with localcontext() as _context:
 _context.prec=400
 _REAL_OVERFLOW_MIDPOINT=Decimal(2)**1024-Decimal(2)**970

def finite_decimal(token):
 value=Decimal(token.replace('D','e').replace('d','e'))
 return value if value.is_finite() and value.copy_abs()<_REAL_OVERFLOW_MIDPOINT else None

def equivalent(a,b,rel_tol=1e-12):
 # Ignore list-directed whitespace, but preserve text and integers exactly.
 # Relative tolerance applies only to ordinary nonzero REAL tokens. Decimal
 # arithmetic must not turn tiny nonzero output into zero before comparison.
 aa=a.split();bb=b.split()
 if len(aa)!=len(bb):return False
 try:
  tolerance=Decimal(str(rel_tol))
  if not tolerance.is_finite() or tolerance<0 or tolerance>=1:return False
  for x,y in zip(aa,bb):
   if NONFINITE.fullmatch(x) or NONFINITE.fullmatch(y):return False
   xi=bool(INTEGER.fullmatch(x));yi=bool(INTEGER.fullmatch(y))
   xr=bool(REAL.fullmatch(x));yr=bool(REAL.fullmatch(y))
   if xi and yi:
    if int(x)!=int(y):return False
   elif (xi or xr) and (yi or yr):
    dx=finite_decimal(x);dy=finite_decimal(y)
    if dx is None or dy is None:return False
    if dx.is_zero() or dy.is_zero():
     if not (dx.is_zero() and dy.is_zero() and dx.is_signed()==dy.is_signed()):return False
    elif xi or yi:
     # Integer/REAL pairs remain exact, even when within the REAL tolerance.
     if dx!=dy:return False
    else:
     with localcontext() as ctx:
      ctx.prec=max(80,len(x)+len(y)+20)
      ctx.Emax=MAX_EMAX;ctx.Emin=MIN_EMIN
      if abs(dx-dy)>tolerance*max(dx.copy_abs(),dy.copy_abs()):return False
   elif x!=y:return False
 except (InvalidOperation,ValueError):
  return False
 return True

def successful_check(result):
 return result['status']==0 and not result['stdout'] and not result['stderr']

def main():
 check_provenance()
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',type=Path,default=ROOT/'results.json');a=ap.parse_args();a.candidate=a.candidate.resolve()
 results=[]
 with tempfile.TemporaryDirectory(prefix='erf-bessel-') as temp:
  temp=Path(temp)
  for c in json.loads((ROOT/'manifest.json').read_text())['cases']:
   src=ROOT/(c['name']+'.f90');assert hashlib.sha256(src.read_bytes()).hexdigest()==c['sha256']
   check=run([a.candidate,'--check',src]);actual=run([a.candidate,src]);expected=c['expected'];oracle=None
   compile=run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow',src,'-o',temp/'oracle'],temp)
   if expected=='run' or c.get('gnu_safe'):
    if compile['status']==0:oracle=run([temp/'oracle'],temp)
   if expected=='run':
    ok=oracle is not None and oracle['status']==0 and not oracle['stderr'] and successful_check(check) and actual['status']==0 and actual['stderr']==c.get('candidate_stderr','') and equivalent(actual['stdout'],oracle['stdout'],c.get('rel_tol',1e-12))
    if 'output' in c:ok=ok and equivalent(actual['stdout'],c['output'])
   elif expected=='runtime':ok=successful_check(check) and actual['status']==2 and not actual['stdout'] and bool(actual['stderr'])
   else:ok=check['status']==1 and actual['status']==1 and not check['stdout'] and not actual['stdout'] and bool(check['stderr']) and bool(actual['stderr'])
   if c.get('gnu_safe'):ok=ok and oracle is not None and oracle['status']==0 and not oracle['stderr'] and equivalent(oracle['stdout'],c['gnu_output'])
   if c.get('diagnostic_contains'):ok=ok and c['diagnostic_contains'].lower() in actual['stderr'].lower()
   ok=ok and ((compile['status']==1 and bool(compile['stderr'])) if c['gnu_compile']=='reject' else compile['status']==0)
   ok=ok and 'Backtrace' not in actual['stderr'] and 'Fortran runtime error' not in actual['stderr']
   results.append(dict(name=c['name'],expected=expected,passed=bool(ok),check=check,actual=actual,compile=compile,oracle=oracle))
   print(('PASS: ' if ok else 'FAIL: ')+c['name'],flush=True)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(results),failed=sum(not c['passed'] for c in results),cases=results)
 a.result.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
