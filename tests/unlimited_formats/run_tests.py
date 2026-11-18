#!/usr/bin/env python3
"""Exact formatted-output bytes, independent structure expectations and GNU."""
import argparse,hashlib,json,re,subprocess,tempfile
from pathlib import Path
from decimal import Decimal,localcontext,MAX_EMAX,MIN_EMIN,InvalidOperation
from check_provenance import check as check_provenance
ROOT=Path(__file__).resolve().parent

def run(args,cwd):
 p=subprocess.run([str(x) for x in args],cwd=cwd,capture_output=True,timeout=60)
 return dict(status=p.returncode,stdout=p.stdout.decode(),stderr=p.stderr.decode())

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

def output_matches(actual,reference,case):
 if case.get('comparison','exact')=='first_formatted_then_list':
  aa=actual.splitlines(keepends=True);bb=reference.splitlines(keepends=True)
  if len(aa)!=2 or len(bb)!=2 or aa[0]!=bb[0]:return False
  # Only the second, original list-directed statement has numeric comparison.
  if not equivalent(aa[1],bb[1]):return False
  if not equivalent(aa[1],'0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0'):return False
 else:
  if actual!=reference:return False
 return 'stdout' not in case or actual==case['stdout']

def main():
 check_provenance()
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',type=Path,default=ROOT/'results.json');a=ap.parse_args();a.candidate=a.candidate.resolve();records=[]
 with tempfile.TemporaryDirectory(prefix='unlimited-format-') as temp:
  temp=Path(temp)
  for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
   p=ROOT/(case['name']+'.f90');assert hashlib.sha256(p.read_bytes()).hexdigest()==case['sha256']
   check=run([a.candidate,'--check',p],temp);actual=run([a.candidate,p],temp)
   compile=run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow',p,'-o',temp/'oracle'],temp);oracle=None
   if case['kind']=='pass':
    if compile['status']==0:oracle=run([temp/'oracle'],temp)
    ok=successful_check(check) and actual['status']==0 and not actual['stderr'] and oracle is not None and oracle['status']==0 and not oracle['stderr'] and output_matches(actual['stdout'],oracle['stdout'],case)
   else:
    status=1 if case['kind']=='reject' else 2
    ok=(check['status']==1 and not check['stdout'] and bool(check['stderr'])) if status==1 else successful_check(check)
    ok=ok and actual['status']==status and actual['stdout']==case.get('prefix','') and bool(actual['stderr']) and case['diagnostic_contains'].lower() in actual['stderr'].lower()
   ok=ok and (compile['status']==0 if case['gnu_compile']=='pass' else compile['status']==1)
   ok=ok and 'Backtrace' not in actual['stderr'] and 'Fortran runtime error' not in actual['stderr']
   records.append(dict(**case,passed=bool(ok),check=check,actual=actual,compile=compile,oracle=oracle))
   print(('PASS: ' if ok else 'FAIL: ')+case['name'],flush=True)
   if not ok:print(repr(dict(check=check,actual=actual,compile=compile))[:1500],flush=True)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(records),failed=sum(not c['passed'] for c in records),cases=records)
 a.result.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
