#!/usr/bin/env python3
"""Independent regression tests for optional headers, scalar PARAMETER and powers."""
import argparse, hashlib, json, math, random, subprocess, tempfile
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path
ROOT=Path(__file__).resolve().parent
CASES=[]
def add(name,source,expected=None,kind='success',oracle=None):
    if oracle is None: oracle='success' if kind=='success' else 'reject' if kind=='reject' else 'skip'
    CASES.append(dict(name=name,source=source,expected=expected,kind=kind,oracle=oracle))
def prog(body,header='program probe\nimplicit none',ending='end program probe'):
    return header+'\n'+body+'\n'+ending+'\n'
add('user_power','print*,2**5\nend\n','32')
add('user_parameter','program main\nimplicit none\ninteger :: i, isum\ninteger, parameter :: imax = 10\nisum = 0\ndo i=1,imax\n   isum = isum + i\nend do\nprint*,isum\nend program main\n','55')
add('implicit_main_declarations','integer :: i\ni=3\nprint*,i\nend\n','3')
add('implicit_main_implicit_none','implicit none\ninteger, parameter :: p=8\nprint*,p\nend\n','8')
add('implicit_main_end_program','print*,42\nend program\n','42')
add('explicit_main_bare_end',prog('print*,7',ending='end'),'7')
add('explicit_main_unnamed_end_program',prog('print*,7',ending='end program'),'7')
add('explicit_no_implicit_none',prog('integer :: i\ni=3\nprint*,i',header='program probe'),'3')
add('empty_implicit_main','end\n','')
add('comments_semicolons','! implicit main\ninteger, parameter :: n = 2; print*,n**3; end ! done\n','8')
add('implicit_named_end_program','print*,42\nend program probe\n',kind='reject')
add('mismatched_end_name',prog('print*,1',ending='end program other'),kind='reject')
add('implicit_missing_end','print*,42\n',kind='reject')
add('implicit_two_programs','print*,1\nend\nprint*,2\nend\n',kind='reject')
add('implicit_undeclared','i=3\nprint*,i\nend\n',kind='reject',oracle='compile')
add('parameter_chained',prog('integer,parameter :: n=3, m=n**2, k=m+n\nprint*,n,m,k'),'3 9 12')
add('parameter_case',prog('integer,parameter :: Value=3, NEXT=value+2\nprint*,VALUE,next'),'3 5')
add('parameter_numeric_conversion',prog('integer,parameter :: n=3.9\nreal,parameter :: r=n\nprint*,n,r'),'3 3')
add('parameter_logical',prog('logical,parameter :: yes=.true., no=.not.yes\nprint*,yes,no'),'T F')
add('parameter_pure_intrinsics',prog('integer,parameter :: n=max(2,abs(-4)), m=mod(n+1,3)\nreal,parameter :: r=real(n)/2.0\nprint*,n,m,r'),'4 2 2')
add('parameter_bounds',prog('integer,parameter :: lower=-2, upper=2\ninteger :: a(lower:upper), i\ndo i=lower,upper\na(i)=i*i\nend do\nprint*,a(-2),a(0),a(upper)'),'4 0 4')
add('parameter_variable_initializer',prog('integer,parameter :: p=2\ninteger :: v=p**5\npRint*,v'),'32')
add('parameter_after_variable_declaration',prog('integer :: v\ninteger,parameter :: p=3\nv=p\nprint*,v'),'3')
add('parameter_zero_extent',prog('integer,parameter :: n=0\ninteger :: a(n)\nprint*,n'),'0')
add('parameter_assignment',prog('integer,parameter :: p=2\nprint*,99\np=4'),kind='reject')
add('parameter_assignment_case',prog('integer,parameter :: Param=2\nPARAM=4'),kind='reject')
add('parameter_do_variable',prog('integer,parameter :: i=1\ndo i=1,3\nprint*,i\nend do'),kind='reject')
add('parameter_variable_dependency',prog('integer :: x=2\ninteger,parameter :: p=x\nprint*,p'),kind='reject')
add('parameter_uninitialized_dependency',prog('integer :: x\ninteger,parameter :: p=x\nprint*,p'),kind='reject')
add('parameter_forward_reference',prog('integer,parameter :: a=b+1, b=2\nprint*,a'),kind='reject')
add('parameter_self_reference',prog('integer,parameter :: a=a+1\nprint*,a'),kind='reject')
add('parameter_duplicate',prog('integer,parameter :: a=1, A=2\nprint*,a'),kind='reject')
add('parameter_redeclare_variable',prog('integer :: a\ninteger,parameter :: a=2\nprint*,a'),kind='reject')
add('parameter_redeclare_parameter',prog('integer,parameter :: a=2\ninteger :: a\nprint*,a'),kind='reject')
add('parameter_program_name',prog('integer,parameter :: probe=2\nprint*,probe'),kind='reject')
add('parameter_missing_value',prog('integer,parameter :: a\nprint*,a'),kind='reject')
add('parameter_missing_second_value',prog('integer,parameter :: a=1,b\nprint*,a'),kind='reject')
add('parameter_integer_logical',prog('integer,parameter :: a=.true.\nprint*,a'),kind='reject')
add('parameter_logical_integer',prog('logical,parameter :: a=1\nprint*,a'),kind='reject')
add('parameter_array_dependency',prog('integer :: a(1)\ninteger,parameter :: p=a(1)\nprint*,p'),kind='reject')
add('parameter_after_executable',prog('print*,1\ninteger,parameter :: p=1\nprint*,p'),kind='reject')
add('parameter_bound_real',prog('real,parameter :: n=2.0\ninteger :: a(n)\nprint*,n'),kind='reject')
add('parameter_divide_zero',prog('integer,parameter :: p=1/0\nprint*,p'),kind='reject')
add('parameter_overflow',prog('integer,parameter :: p=2**31\nprint*,p'),kind='reject')
add('parameter_minimum_integer',prog('integer,parameter :: p=-2147483647-1\nprint*,p'),'-2147483648')
add('parameter_nonconstant_bound',prog('integer :: n=2\ninteger,parameter :: p=3\ninteger :: a(n+p)\nprint*,p'),kind='reject')
add('power_precedence',prog('print*,2**3**2,-2**2,(-2)**2,2*3**2,2**3*2'),'512 -4 4 18 16')
add('power_negative_integer_exponents',prog('print*,2**(-1),2**(-3),(-2)**(-3),(-1)**(-3),(-1)**(-4),1**(-4)'),'0 0 0 -1 1 1')
add('power_zero_exponents',prog('print*,0**0,1**0,(-1)**0,2**0'),'1 1 1 1')
add('power_extreme_exponents',prog('integer :: n\nn=-2147483647-1\nprint*,(-1)**n,1**n,2**n,(-2)**n'),'1 1 0 0')
add('power_large_positive_exponents',prog('integer :: n=2147483647\nprint*,(-1)**n,1**n,0**n'),'-1 1 0')
add('power_int_boundary',prog('print*,2**30,(-2)**31'),'1073741824 -2147483648')
add('power_mixed_real',prog('print*,2.0**3,2**3.0,(-2.0)**3,(-2.0)**(-3)'),'8 8 -8 -0.125')
add('power_overflow_dynamic',prog('integer :: n=31\nprint*,2**n'),kind='runtime')
add('power_zero_negative_dynamic',prog('integer :: n=-1\nprint*,0**n'),kind='runtime')
add('power_real_domain_dynamic',prog('real :: r=-2.0, n=2.0\nprint*,r**n'),kind='runtime')
add('implicit_main_name_is_variable','integer :: main\nmain=3\nprint*,main\nend\n','3')
add('implicit_main_name_is_parameter','integer,parameter :: main=3\nprint*,main\nend\n','3')
add('parameter_real32_conversion',prog('integer,parameter :: n=16777217\nreal,parameter :: r=n\ninteger,parameter :: m=int(r)\nprint*,n,r,m'),'16777217 16777216 16777216')
add('parameter_logic_expression',prog('integer,parameter :: n=3\nlogical,parameter :: positive=n>0, bigger=n>4\nif (positive.and..not.bigger) then\nprint*,n\nend if'),'3')
add('parameter_runtime_copy_independent',prog('integer,parameter :: n=2\ninteger :: x=n\nx=x+1\nprint*,n,x'),'2 3')
add('parameter_extreme_power',prog('integer,parameter :: n=-2147483647-1, p=(-1)**n, q=2**n\nprint*,p,q'),'1 0')
add('parameter_dead_assignment',prog('integer,parameter :: p=2\nif (.false.) then\np=4\nend if'),kind='reject')
add('parameter_dependency_converts_before_use',prog('integer,parameter :: n=3.9, m=n*2\nreal,parameter :: r=m/4.0\nprint*,n,m,r'),'3 6 1.5')
# The pinned frontend cannot resolve this keyword as an ordinary identifier.
# Keep the prototype's documented reserved-name boundary explicit.
add('unsupported_parameter_name_scalar','integer :: parameter\nparameter=3\nprint*,parameter\nend\n',kind='reject',oracle='compile')
add('unsupported_parameter_name_constant','integer,parameter :: parameter=3\nprint*,parameter\nend\n',kind='reject',oracle='compile')
add('unsupported_parameter_name_program','program parameter\nprint*,3\nend program parameter\n',kind='reject',oracle='compile')
# Deterministic independent small-integer arithmetic model for chained constants.
rng=random.Random(20261114)
for i in range(20):
 a=rng.randrange(-7,8); b=rng.randrange(1,7); c=a*a+b; d=c**3; e=d%c
 source=prog(f'integer,parameter :: a={a}, b={b}, c=a*a+b, d=c**3, e=mod(d,c)\ninteger :: x=d\nprint*,a,b,c,d,e,x')
 add(f'parameter_model_{i:02d}',source,f'{a} {b} {c} {d} {e} {d}')

def run(command,timeout=10):
 try:
  p=subprocess.run(command,text=True,capture_output=True,timeout=timeout)
  return dict(command=list(map(str,command)),returncode=p.returncode,stdout=p.stdout,stderr=p.stderr)
 except subprocess.TimeoutExpired as e:
  def text(value): return value.decode(errors='replace') if isinstance(value,bytes) else value or ''
  return dict(command=list(map(str,command)),returncode=None,timeout=True,stdout=text(e.stdout),stderr=text(e.stderr))
def compare(actual,expected):
 x=actual.split(); y=expected.split()
 if len(x)!=len(y): return False
 for a,b in zip(x,y):
  if a==b: continue
  try:
   if b.lstrip('+-').isdigit():
    if Decimal(a)!=Decimal(b): return False
   elif not math.isclose(float(a),float(b),rel_tol=2e-6,abs_tol=1e-7): return False
  except (ValueError,InvalidOperation): return False
 return True

def candidate_errors(c, check, exec_):
 errors=[]
 if c['kind']=='success':
  if check['returncode']!=0 or check['stdout']: errors.append('check rejected or emitted output')
  if exec_['returncode']!=0 or not compare(exec_['stdout'],c['expected']): errors.append('execution mismatch')
 elif c['kind']=='reject':
  if check['returncode']!=1 or check['stdout'] or exec_['returncode']!=1 or exec_['stdout']: errors.append('expected compile rejection with no output')
 else:
  if check['returncode']!=0 or check['stdout']: errors.append('runtime case rejected at compile time')
  if exec_['returncode']!=2 or exec_['stdout']: errors.append('expected runtime error with no output')
 if c['kind']!='success' and (not exec_['stderr'] or (c['kind']=='reject' and not check['stderr'])): errors.append('missing error diagnostic')
 return errors

def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--gfortran');p.add_argument('--output',default='results.json');p.add_argument('--only');args=p.parse_args()
 selected=[c for c in CASES if not args.only or args.only in c['name']]
 source_dir=ROOT/'cases'; source_dir.mkdir(exist_ok=True); records=[]
 (ROOT/'manifest.json').write_text(json.dumps(dict(schema_version=1,cases=CASES),indent=2)+'\n')
 for c in selected:
  path=source_dir/(c['name']+'.f90');path.write_text(c['source']); row=dict(case=c)
  check=run([args.candidate,'--check',str(path)]);exec_=run([args.candidate,str(path)])
  errors=candidate_errors(c,check,exec_)
  row['candidate']=dict(passed=not errors,errors=errors,check=check,run=exec_)
  if args.gfortran and c['oracle']!='skip':
   with tempfile.TemporaryDirectory() as td:
    binary=str(Path(td)/'reference'); build=run([args.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',str(path),'-o',binary]); ref_errors=[]; ref=dict(compile=build)
    if c['oracle']=='reject':
     if build['returncode'] is None or build['returncode']<=0 or not build['stderr']:ref_errors.append('expected GNU compile rejection')
    elif build['returncode']!=0:ref_errors.append('GNU compilation failed')
    elif c['oracle']=='success':
     ref['run']=run([binary])
     if ref['run']['returncode']!=0 or not compare(ref['run']['stdout'],c['expected']): ref_errors.append('GNU output mismatch')
    ref.update(passed=not ref_errors,errors=ref_errors);row['gnu']=ref
  elif args.gfortran: row['gnu']=dict(skipped=True,reason='Interpreter checked-runtime safety policy; invalid/overflowing arithmetic is not a portable GNU semantic oracle.')
  records.append(row)
  print(c['name']+': candidate '+('PASS' if row['candidate']['passed'] else 'FAIL: '+str(errors))+'; GNU '+('SKIP' if row.get('gnu',{}).get('skipped') else 'PASS' if row.get('gnu',{}).get('passed') else 'FAIL' if args.gfortran else 'not run'),flush=True)
 counts={key:dict(total=len(records),passed=sum(r.get(key,{}).get('passed',False) for r in records),skipped=sum(r.get(key,{}).get('skipped',False) for r in records),failed=sum(key in r and not r[key].get('passed') and not r[key].get('skipped') for r in records)) for key in ('candidate','gnu')}
 payload=dict(recorded_utc=datetime.now(timezone.utc).isoformat(),summary=counts,source_sha256={c['name']:hashlib.sha256(c['source'].encode()).hexdigest() for c in selected},candidate_sha256=hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest(),records=records,gnu_version=run([args.gfortran,'--version']) if args.gfortran else None)
 (ROOT/args.output).write_text(json.dumps(payload,indent=2)+'\n');print(json.dumps(counts,indent=2));return int(any(v['failed'] for v in counts.values()))
if __name__=='__main__':raise SystemExit(main())
