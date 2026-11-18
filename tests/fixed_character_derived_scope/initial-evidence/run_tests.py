from pathlib import Path
import argparse,json,subprocess,tempfile,hashlib,re
R=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0','-ffree-line-length-none']
def compare(a,b,integer_records=()):
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
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--gfortran');ap.add_argument('--candidate');ap.add_argument('--result',type=Path,default=R/'results.json');a=ap.parse_args();rows=[]
 if not(a.gfortran or a.candidate):ap.error('Choose an executable')
 if a.candidate:a.candidate=str(Path(a.candidate).resolve())
 if a.gfortran and '/' in a.gfortran:a.gfortran=str(Path(a.gfortran).resolve())
 meta=json.loads((R/'provenance.json').read_text())
 for item in meta['files']:assert hashlib.sha256((R/item['file']).read_bytes()).hexdigest()==item['sha256']
 identity=hashlib.sha256(Path(a.candidate).read_bytes()).hexdigest() if a.candidate else None
 with tempfile.TemporaryDirectory(prefix='slash-gnu-') as tmp:
  for c in json.loads((R/'manifest.json').read_text())['cases']:
   src=R/c['source'];assert hashlib.sha256(src.read_bytes()).hexdigest()==c['sha256'];row={'case':c,'errors':[]};errors=row['errors']
   if a.gfortran:
    q=run([a.gfortran,*FLAGS,src,'-o',Path(tmp)/'a'],tmp);row['gnu_compile']=q
    if c['gnu']=='reject':
     if q['code']!=1 or not q['err'] or q['out']:errors.append('GNU compile rejection differs')
    elif q['code']!=0 or q['out'] or q['err']:errors.append('GNU compilation differs')
    elif c['gnu']=='run':
     q=run([Path(tmp)/'a'],tmp);row['gnu_run']=q
     if q['code']!=0 or q['err'] or not compare(q['out'],c.get('gnu_expected',c['expected']),c['integer_records']):errors.append('GNU execution differs')
   if a.candidate:
    chk=run([a.candidate,'--check',src],tmp);q=run([a.candidate,*[v for item in c.get('inputs',[]) for v in ['--input',str(item['unit'])+'='+str(R/item['file'])]],src],tmp);row.update(check=chk,run=q)
    if c['stage']=='reject':
     if chk['code']!=1 or chk['out'] or not chk['err']:errors.append('CHECK rejection differs')
    elif chk!={'code':0,'out':'','err':''}:errors.append('CHECK differs')
    if c['stage']=='success':
     if q['code']!=0 or q['err'] or not compare(q['out'],c['expected'],c['integer_records']):errors.append('candidate execution differs')
    else:
     if q['code']!=(1 if c['stage']=='reject' else 2) or q['out']!=c['expected']:errors.append('candidate failure stage/output differs')
     d=c['diagnostic']
     if not d or q['err']!=str(src)+':'+d+'\n':errors.append('unpinned or mismatched exact diagnostic')
   assert hashlib.sha256(src.read_bytes()).hexdigest()==c['sha256'];rows.append(row);print(c['name'],errors or 'PASS')
 if a.candidate:assert hashlib.sha256(Path(a.candidate).read_bytes()).hexdigest()==identity
 summary={'candidate_sha256':identity,'total':len(rows),'failed':sum(bool(r['errors']) for r in rows)};a.result.write_text(json.dumps({'summary':summary,'records':rows},indent=2)+'\n');print(summary)
 return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
