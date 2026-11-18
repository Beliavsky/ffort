"""Exact source closure, variable clock result: compare format/invariants, not timestamps."""
from pathlib import Path
import argparse,hashlib,json,re,subprocess,tempfile
from decimal import Decimal
R=Path(__file__).resolve().parent
SOURCE=R/'source/original_print_wall_time_elapsed.f90'
SHA='64a1890fbd0fb5753ab5e1cad645eb5a4798325467c0e81867e9c8b39331fc1a'
def valid_output(raw):
 m=re.fullmatch(rb'\n wall time elapsed\(s\) = (.{9})\n',raw)
 if not m:return False
 field=m[1]
 if not re.fullmatch(rb' *[0-9]+\.[0-9]{3}',field):return False
 return Decimal(field.decode().strip())>=0
def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate');p.add_argument('--gfortran');p.add_argument('--result',type=Path,default=R/'utility-results.json');a=p.parse_args()
 if not(a.candidate or a.gfortran):p.error('Choose candidate and/or GNU compiler')
 assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SHA
 rows=[]
 with tempfile.TemporaryDirectory(prefix='slash-utility-') as tmp:
  for label,app in [('candidate',a.candidate),('gnu',a.gfortran)]:
   if not app:continue
   app=str(Path(app).resolve()) if '/' in app or label=='candidate' else app
   identity=hashlib.sha256(Path(app).read_bytes()).hexdigest() if label=='candidate' else None
   cmd=[app,'--check',str(SOURCE)] if label=='candidate' else [app,'-std=f2018','-pedantic-errors','-fcheck=all','-O0','-ffree-line-length-none',str(SOURCE),'-o',tmp+'/utility']
   c=subprocess.run(cmd,cwd=tmp,capture_output=True,timeout=30)
   row={'label':label,'identity':identity,'check':{'code':c.returncode,'out':c.stdout.decode('latin1'),'err':c.stderr.decode('latin1')}};row['passed']=c.returncode==0 and not c.stdout and not c.stderr
   if row['passed']:
    q=subprocess.run([app,str(SOURCE)] if label=='candidate' else [tmp+'/utility'],cwd=tmp,capture_output=True,timeout=30)
    row['run']={'code':q.returncode,'out':q.stdout.decode('latin1'),'err':q.stderr.decode('latin1')};row['passed']=q.returncode==0 and q.stderr==b'' and valid_output(q.stdout)
   if identity:assert hashlib.sha256(Path(app).read_bytes()).hexdigest()==identity
   rows.append(row)
 assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SHA
 a.result.write_text(json.dumps({'source_sha256':SHA,'rows':rows,'passed':all(r['passed'] for r in rows)},indent=2)+'\n')
 print([(r['label'],r['passed']) for r in rows]);return not all(r['passed'] for r in rows)

if __name__=='__main__':raise SystemExit(main())
