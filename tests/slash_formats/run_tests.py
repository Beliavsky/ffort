from pathlib import Path
import argparse,json,subprocess,tempfile,hashlib,re
R=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0','-ffree-line-length-none']
def compare(a,b,integer_records=()):
 if not integer_records:return a==b
 aa=a.splitlines(keepends=True);bb=b.splitlines(keepends=True)
 if len(aa)!=len(bb):return False
 for i,(x,y) in enumerate(zip(aa,bb)):
  if i not in integer_records:
   if x!=y:return False
  else:
   if x.endswith('\n')!=y.endswith('\n'):return False
   u,v=x.split(),y.split()
   if len(u)!=len(v) or not all(re.fullmatch(r'[+-]?\d+',z) for z in u+v):return False
   if [int(z) for z in u]!=[int(z) for z in v]:return False
 return True
def run(argv,cwd):
 try:
  p=subprocess.run(list(map(str,argv)),cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=30)
  return dict(code=p.returncode,out=p.stdout.decode('latin1'),err=p.stderr.decode('latin1'))
 except (OSError,subprocess.TimeoutExpired) as e:return dict(code=None,out='',err=str(e))
def candidate_errors(case,check,execution,source):
 errors=[]
 stage=case['stage']
 if stage not in ('success','runtime','compile'):return ['unknown candidate stage']
 diagnostic=case.get('diagnostic')
 if stage!='success' and (not isinstance(diagnostic,str) or not re.fullmatch(r'[1-9][0-9]*:[1-9][0-9]*: [^\r\n]+',diagnostic)):
  return ['unpinned or malformed exact diagnostic']
 stderr=str(source)+':'+diagnostic+'\n' if stage!='success' else ''
 expected_check={'code':1,'out':'','err':stderr} if stage=='compile' else {'code':0,'out':'','err':''}
 if check!=expected_check:errors.append('CHECK differs')
 if stage=='success':
  if execution['code']!=0 or execution['err']!='' or not compare(execution['out'],case['expected'],case['integer_records']):
   errors.append('candidate execution differs')
 elif execution!={'code':1 if stage=='compile' else 2,'out':case['expected'],'err':stderr}:
  errors.append('candidate failure stage/output/diagnostic differs')
 return errors
def gnu_errors(case,compilation,execution=None):
 if compilation!={'code':0,'out':'','err':''}:return ['GNU compilation differs']
 if case['gnu']=='compile':return []
 if case['gnu']!='run':return ['unknown GNU stage']
 if execution is None or execution['code']!=0 or execution['err']!='' or not compare(execution['out'],case['expected'],case['integer_records']):
  return ['GNU execution differs']
 return []
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--gfortran');ap.add_argument('--candidate');ap.add_argument('--result',type=Path,default=R/'results.json');a=ap.parse_args();rows=[]
 if not(a.gfortran or a.candidate):ap.error('Choose an executable')
 if a.candidate:a.candidate=str(Path(a.candidate).resolve())
 if a.gfortran and '/' in a.gfortran:a.gfortran=str(Path(a.gfortran).resolve())
 meta=json.loads((R/'provenance.json').read_text())
 assert hashlib.sha256((R/'source/demo_btest.f90').read_bytes()).hexdigest()==meta['original_sha256']
 identity=hashlib.sha256(Path(a.candidate).read_bytes()).hexdigest() if a.candidate else None
 with tempfile.TemporaryDirectory(prefix='slash-gnu-') as tmp:
  for c in json.loads((R/'manifest.json').read_text())['cases']:
   src=R/c['source'];assert hashlib.sha256(src.read_bytes()).hexdigest()==c['sha256'];row={'case':c,'errors':[]};errors=row['errors']
   if a.gfortran:
    comp=run([a.gfortran,*FLAGS,src,'-o',Path(tmp)/'a'],tmp);row['gnu_compile']=comp;execution=None
    if comp=={'code':0,'out':'','err':''} and c['gnu']=='run':
     execution=run([Path(tmp)/'a'],tmp);row['gnu_run']=execution
    errors.extend(gnu_errors(c,comp,execution))
   if a.candidate:
    chk=run([a.candidate,'--check',src],tmp);q=run([a.candidate,src],tmp);row.update(check=chk,run=q)
    errors.extend(candidate_errors(c,chk,q,src))
   assert hashlib.sha256(src.read_bytes()).hexdigest()==c['sha256'];rows.append(row);print(c['name'],errors or 'PASS')
 if a.candidate:assert hashlib.sha256(Path(a.candidate).read_bytes()).hexdigest()==identity
 summary={'candidate_sha256':identity,'total':len(rows),'failed':sum(bool(r['errors']) for r in rows)};a.result.write_text(json.dumps({'summary':summary,'records':rows},indent=2)+'\n');print(summary)
 return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
