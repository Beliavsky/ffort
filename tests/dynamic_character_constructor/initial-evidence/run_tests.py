#!/usr/bin/env python3
"""Independent explicit-output oracles; GNU never serves as an execution fallback."""
from pathlib import Path
from decimal import Decimal,InvalidOperation
import argparse,json,hashlib,re,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0','-ffree-line-length-none']
NUM=re.compile(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[dDeE][+-]?\d+)?$')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def numeric_equal(a,b):
 if not NUM.fullmatch(a) or not NUM.fullmatch(b):return a==b and not re.fullmatch(r'[+-]?(nan|inf|infinity)',a,re.I)
 try:x,y=Decimal(a.lower().replace('d','e')),Decimal(b.lower().replace('d','e'))
 except InvalidOperation:return False
 return x.is_finite() and y.is_finite() and x==y and (x!=0 or x.is_signed()==y.is_signed())
def compare(actual,expected,mode='exact'):
 if mode=='exact':return actual==expected
 if mode!='numeric_records':raise ValueError('Unknown comparison mode')
 if actual.endswith('\n')!=expected.endswith('\n') or '\r' in actual or '\r' in expected:return False
 aa,bb=actual.split('\n'),expected.split('\n')
 return len(aa)==len(bb) and all(len(a.split())==len(b.split()) and all(numeric_equal(x,y) for x,y in zip(a.split(),b.split())) for a,b in zip(aa,bb))
def run(argv,cwd):
 try:
  q=subprocess.run(list(map(str,argv)),cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=30)
  return dict(code=q.returncode,out=q.stdout.decode('latin1'),err=q.stderr.decode('latin1'))
 except (subprocess.TimeoutExpired,OSError) as e:return dict(code=None,out='',err=str(e))
def candidate_errors(c,check,execution,source):
 errors=[];stage=c['stage'];want_check=1 if stage=='reject' else 0;want_run={'success':0,'runtime':2,'reject':1}[stage]
 for label,result,want in [('check',check,want_check),('run',execution,want_run)]:
  if result['code']!=want:errors.append(label+' exit differs')
  if not want and result['err']!='':errors.append(label+' successful stderr not empty')
  if want and not result['err']:errors.append(label+' diagnostic missing')
 if check['out']!='':errors.append('CHECK stdout not empty')
 if not compare(execution['out'],c['expected_stdout'],c.get('mode','exact')):errors.append('execution stdout differs')
 if stage!='success':
  d=c.get('diagnostic')
  if not isinstance(d,dict):errors.append('Unpinned diagnostic contract')
  else:
   expected=str(source)+':'+str(d['line'])+':'+str(d['column'])+': '+d['message']+'\n'
   if execution['err']!=expected:errors.append('Exact diagnostic differs')
   if stage=='reject' and check['err']!=expected:errors.append('Exact CHECK diagnostic differs')
 return errors
def validate_original(path):
 meta=json.loads((ROOT/'provenance.json').read_text());data=path.read_bytes()
 if hashlib.sha256(data).hexdigest()!=meta['original_sha256']:raise ValueError('Original identity differs')
 lines=data.splitlines(keepends=True);first,last=meta['original_lines'];body=b''.join(lines[first-1:last])
 if hashlib.sha256(body).hexdigest()!=meta['body_sha256']:raise ValueError('Original range differs')
 for name in meta['original_cases']:
  if (ROOT/'cases'/(name+'.f90')).read_bytes().count(body)!=1:raise ValueError('Original body not retained: '+name)
 for entry in meta.get('additional_original_bodies',[]):
  first,last=entry['lines'];body=b''.join(lines[first-1:last])
  if hashlib.sha256(body).hexdigest()!=entry['sha256']:raise ValueError('Dependency identity differs')
  for name in entry['cases']:
   if (ROOT/'cases'/(name+'.f90')).read_bytes().count(body)!=1:raise ValueError('Dependency body not retained: '+name)
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--gfortran');ap.add_argument('--candidate',type=Path);ap.add_argument('--only',default='');ap.add_argument('--result',type=Path,default=ROOT/'results.json');ap.add_argument('--original-source',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90');args=ap.parse_args()
 if not args.gfortran and not args.candidate:ap.error('Select candidate and/or GNU')
 validate_original(args.original_source);cases=[c for c in json.loads((ROOT/'manifest.json').read_text())['cases'] if re.search(args.only,c['name'])]
 if not cases:ap.error('No selected cases')
 if args.candidate:args.candidate=args.candidate.resolve();before=sha(args.candidate)
 rows=[]
 for c in cases:
  source=(ROOT/c['source']).resolve()
  if sha(source)!=c['sha256']:raise ValueError('Source identity differs '+c['name'])
  row=dict(case=c,errors=[])
  with tempfile.TemporaryDirectory(prefix='dynamic-char-oracle-') as folder:
   folder=Path(folder)
   if args.gfortran:
    q=run([args.gfortran,*FLAGS,source,'-o',folder/'oracle'],folder);row['gnu_compile']=q
    if c['gnu']=='reject':
     if q['code']!=1 or q['out']!='' or c.get('gnu_diagnostic','') not in q['err']:row['errors'].append('GNU known rejection differs')
    elif q['code']!=0 or q['out']!='' or q['err']!='':row['errors'].append('GNU compile is not clean success')
    elif c['gnu']=='run':
     q=run([folder/'oracle'],folder);row['gnu_run']=q
     if q['code']!=0 or q['err']!='' or not compare(q['out'],c['expected_stdout'],c.get('mode','exact')):row['errors'].append('GNU execution/oracle differs')
   if args.candidate:
    check=run([args.candidate,'--check',source],folder);execution=run([args.candidate,source],folder);row.update(check=check,run=execution);row['errors']+=candidate_errors(c,check,execution,source)
  if sha(source)!=c['sha256']:row['errors'].append('Source changed during test')
  print(c['name']+(': PASS' if not row['errors'] else ': FAIL '+', '.join(row['errors'])),flush=True);rows.append(row)
 summary=dict(total=len(rows),failed=sum(bool(r['errors']) for r in rows),gnu_executed=sum('gnu_run'in r for r in rows),gnu_compile_only=sum(c['gnu']=='compile' for c in cases),gnu_compile_rejections=sum(c['gnu']=='reject' for c in cases))
 result=dict(summary=summary,records=rows,manifest_sha256=sha(ROOT/'manifest.json'))
 if args.candidate:
  result.update(candidate_sha256=before,candidate_final_sha256=sha(args.candidate))
  if before!=sha(args.candidate):summary['failed']+=1
 args.result.write_text(json.dumps(result,indent=2)+'\n');print(summary);return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
