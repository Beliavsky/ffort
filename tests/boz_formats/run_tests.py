#!/usr/bin/env python3
"""Bounded B/O/Z output: exact byte oracle, no numeric normalization."""
from pathlib import Path
from decimal import Decimal,InvalidOperation
import argparse,hashlib,json,re,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
NUMBER=re.compile(r'[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eEdD][+-]?[0-9]+)?\Z')
INTEGER=re.compile(r'[+-]?[0-9]+\Z')
CRASH=re.compile(r'backtrace|traceback|fortran runtime error|internal compiler error|segmentation fault|SIGSEGV|SIGABRT|core dumped|addresssanitizer|undefinedbehaviorsanitizer|\bICE\b|TIMEOUT',re.I)
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def execute(argv,cwd,executable=None):
 try:
  p=subprocess.run(list(map(str,argv)),cwd=cwd,executable=executable,stdin=subprocess.DEVNULL,capture_output=True,timeout=30)
  return dict(code=p.returncode,out=p.stdout.decode('latin-1'),err=p.stderr.decode('latin-1'))
 except subprocess.TimeoutExpired:return dict(code=None,out='',err='TIMEOUT')
 except OSError as e:return dict(code=None,out='',err=str(e))
def clean(r):return not CRASH.search(r['out']+'\n'+r['err'])
def silent(r):return r==dict(code=0,out='',err='')
def compare(actual,expected,numeric_lines=()):
 # Records, endings and all nonnumeric lines are byte-exact. Numeric lines have
 # opt-in exact Decimal token equality, not float/tolerance comparisons.
 a=actual.splitlines(keepends=True);b=expected.splitlines(keepends=True)
 if len(a)!=len(b):return False
 for i,(x,y) in enumerate(zip(a,b)):
  if i not in numeric_lines:
   if x!=y:return False
   continue
  ending=lambda s:'\r\n' if s.endswith('\r\n') else '\n' if s.endswith('\n') else '\r' if s.endswith('\r') else ''
  if ending(x)!=ending(y):return False
  xe=ending(x);ye=ending(y)
  xb=x[:-len(xe)] if xe else x;yb=y[:-len(ye)] if ye else y
  xs=re.split(r'[ \t]+',xb.strip(' \t')) if xb.strip(' \t') else []
  ys=re.split(r'[ \t]+',yb.strip(' \t')) if yb.strip(' \t') else []
  if len(xs)!=len(ys):return False
  if not xs:
   if x!=y:return False
   continue
  for u,v in zip(xs,ys):
   if not NUMBER.fullmatch(u) or not NUMBER.fullmatch(v):return False
   if INTEGER.fullmatch(v) and u!=v:return False
   try:
    ud=Decimal(u.replace('D','E').replace('d','e'));vd=Decimal(v.replace('D','E').replace('d','e'))
   except InvalidOperation:return False
   if not ud.is_finite() or not vd.is_finite() or ud!=vd:return False
   if ud.is_zero() and ud.is_signed()!=vd.is_signed():return False
 return True
def diagnostic_matches(result,case,source):
 pattern=re.escape(str(source)+':'+str(case['diagnostic_line'])+':'+str(case['diagnostic_column'])+': '+case['diagnostic'])+r'\n'
 return clean(result) and re.fullmatch(pattern,result['err']) is not None
def candidate_errors(case,source,check,ran):
 errors=[]
 if case['category']=='reject':
  if check['code']!=1 or check['out'] or not diagnostic_matches(check,case,source):errors.append('static rejection check differs')
 elif not silent(check):errors.append('check must succeed silently')
 status=0 if case['category']=='success' else 1 if case['category']=='reject' else 2
 if ran['code']!=status:errors.append('wrong execution status')
 if not clean(ran):errors.append('host crash/timeout marker')
 if not compare(ran['out'],case['expected_stdout'],case.get('numeric_lines',())):errors.append('output mismatch')
 if status==0:
  if ran['err']!='':errors.append('successful stderr')
 elif not diagnostic_matches(ran,case,source):errors.append('missing exact source-located diagnostic')
 return errors
def oracle_errors(case,compiled,ran):
 errors=[]
 if case['gnu']=='known-reject':
  if compiled['code']!=1 or compiled['out'] or not clean(compiled) or case['gnu_compile_diagnostic'].lower() not in compiled['err'].lower():errors.append('known GNU compiler diagnostic differs')
  if ran is not None:errors.append('known rejected GNU source must not execute')
  return errors
 if not silent(compiled):errors.append('GNU compile did not succeed silently')
 if case['gnu']=='compile':
  if ran is not None:errors.append('compile-only GNU must not execute')
 else:
  if ran is None:errors.append('GNU execution missing')
  elif ran['code']!=0 or ran['err'] or not clean(ran) or not compare(ran['out'],case.get('gnu_expected_stdout',case['expected_stdout']),case.get('numeric_lines',())):errors.append('GNU output/status differs from independent expectation')
 return errors
def validate_cases(cases):
 names=set()
 for c in cases:
  if not re.fullmatch('[a-z][a-z0-9_]*',c['name']) or c['name'] in names:raise ValueError('invalid or duplicate case name')
  names.add(c['name'])
  if c.get('numeric_lines'):raise ValueError('BOZ records require byte-exact comparisons')
  if c['source']!='cases/'+c['name']+'.f90':raise ValueError('invalid source path')
  if c['category'] not in ('success','runtime','reject') or c['gnu'] not in ('run','compile','known-reject'):raise ValueError('invalid stage contract')
  if c['gnu']=='known-reject' and not c.get('gnu_compile_diagnostic'):raise ValueError('missing GNU limitation diagnostic')
  if c['category']!='success' and (not c.get('diagnostic') or c.get('diagnostic_line',0)<=0 or c.get('diagnostic_column',0)<=0):raise ValueError('missing diagnostic contract')
  units=set();total=0
  for f in c.get('inputs',[]):
   unit=f['unit'];path=Path(f['file'])
   if type(unit) is not int or unit<=0 or unit>2147483647 or unit in units:raise ValueError('invalid or duplicate input unit')
   units.add(unit)
   if path.is_absolute() or path.parts[0]!='inputs' or '..' in path.parts:raise ValueError('unsafe fixture input path')
   if f['bytes']<0 or f['bytes']>1048576:raise ValueError('input size outside cap')
   total+=f['bytes']
  if len(units)>32 or total>4194304:raise ValueError('aggregate input cap exceeded')
def verify_source_identity(cases):
 identity=json.loads((ROOT/'SOURCE-IDENTITY.json').read_text())['sources']
 pinned={r['name']:(r['file'],r['sha256']) for r in identity}
 actual={r['name']:(r['source'],r['sha256']) for r in cases}
 if len(pinned)!=len(identity) or pinned!=actual:raise ValueError('independent source identity differs')
 input_identity=json.loads((ROOT/'SOURCE-IDENTITY.json').read_text()).get('inputs',[])
 expected_inputs=[dict(case=c['name'],**f) for c in cases for f in c.get('inputs',[])]
 if input_identity!=expected_inputs:raise ValueError('independent input identity differs')
 for f in expected_inputs:
  if sha(ROOT/f['file'])!=f['sha256'] or (ROOT/f['file']).stat().st_size!=f['bytes']:raise ValueError('pinned input bytes changed')
 for name,(file,digest) in pinned.items():
  if sha(ROOT/file)!=digest:raise ValueError('pinned source bytes changed: '+name)
def prepare_inputs(case,work):
 gnu_work=work/'gnu';gnu_work.mkdir();candidate_work=work/'candidate';candidate_work.mkdir()
 bindings=[];inputs={}
 for f in case.get('inputs',[]):
  original=ROOT/f['file']
  if sha(original)!=f['sha256'] or original.stat().st_size!=f['bytes']:raise ValueError('pinned input bytes changed')
  native=gnu_work/('fort.'+str(f['unit']));native.write_bytes(original.read_bytes())
  target=candidate_work/('input_'+str(f['unit'])+'.dat');target.write_bytes(original.read_bytes())
  bindings.extend(['--input',str(f['unit'])+'='+str(target)]);inputs[target]=f['sha256'];inputs[native]=f['sha256']
 return gnu_work,candidate_work,bindings,inputs
def input_errors(inputs,candidate_work):
 errors=[]
 if not all(p.is_file() and sha(p)==h for p,h in inputs.items()):errors.append('input file changed or missing')
 expected_files={p.name for p in inputs if p.parent==candidate_work}
 if {p.name for p in candidate_work.iterdir()}!=expected_files:errors.append('unexpected native file in candidate cwd')
 return errors
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path);ap.add_argument('--gfortran',required=True);ap.add_argument('--result',type=Path,default=ROOT/'results.json');args=ap.parse_args();candidate=args.candidate.resolve() if args.candidate else None
 cases=json.loads((ROOT/'manifest.json').read_text())['cases'];validate_cases(cases);verify_source_identity(cases);records=[];candidate_hash=sha(candidate) if candidate else None
 with tempfile.TemporaryDirectory(prefix='boz-formats-') as folder:
  temp=Path(folder)
  for c in cases:
   work=temp/c['name'];work.mkdir();source=(ROOT/c['source']).resolve();assert sha(source)==c['sha256']
   # GNU fort.N and candidate --input files are separate pinned copies.
   gnu_work,candidate_work,bindings,inputs=prepare_inputs(c,work)
   compiled=execute([args.gfortran,*c.get('gnu_flags',['-std=f2018','-pedantic-errors']),'-fcheck=all','-ffpe-trap=invalid,zero,overflow','-O0',source,'-o',gnu_work/'oracle'],gnu_work)
   oracle=execute([source],gnu_work,executable=str(gnu_work/'oracle')) if c['gnu']=='run' and silent(compiled) else None
   errors=oracle_errors(c,compiled,oracle);row=dict(name=c['name'],source_sha256=c['sha256'],inputs=c.get('inputs',[]),compiled=compiled,oracle=oracle)
   if candidate:
    check=execute([candidate,'--check',*bindings,source],candidate_work);ran=execute([candidate,*bindings,source],candidate_work);errors+=candidate_errors(c,source,check,ran);row.update(check=check,ran=ran)
    if c['category']=='success' and not c.get('numeric_lines') and oracle is not None and ran['out']!=oracle['out']:errors.append('byte-exact GNU mismatch')
   errors+=input_errors(inputs,candidate_work)
   if sha(source)!=c['sha256']:errors.append('source changed')
   row['errors']=errors;records.append(row);print(('PASS ' if not errors else 'FAIL ')+c['name'],flush=True)
   if errors:print(repr(row)[:2000],flush=True)
 result=dict(candidate=str(candidate) if candidate else None,candidate_sha256=candidate_hash,candidate_sha256_after=sha(candidate) if candidate else None,total=len(records),failed=sum(bool(r['errors']) for r in records),gnu_executed=sum(c['gnu']=='run' for c in cases),gnu_compile_only=sum(c['gnu']=='compile' for c in cases),gnu_known_rejections=sum(c['gnu']=='known-reject' for c in cases),records=records)
 if result['candidate_sha256']!=result['candidate_sha256_after']:result['failed']+=1
 args.result.write_text(json.dumps(result,indent=2)+'\n');print('Total',result['total'],'failed',result['failed']);return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
