from pathlib import Path
import subprocess,tempfile,json,hashlib,argparse
from oracle_contracts import oracle_check
R=Path(__file__).resolve().parent
def execute(cmd,cwd):
 try:
  p=subprocess.run(list(map(str,cmd)),cwd=cwd,capture_output=True,text=True,timeout=30,stdin=subprocess.DEVNULL)
  return dict(code=p.returncode,stdout=p.stdout,stderr=p.stderr)
 except subprocess.TimeoutExpired:return dict(code=None,stdout='',stderr='TIMEOUT')
 except OSError as e:return dict(code=None,stdout='',stderr=str(e))
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--gfortran',required=True,type=Path);ap.add_argument('--results',type=Path,default=R/'gnu-strict-results.json');args=ap.parse_args();FC=args.gfortran.resolve();rows=[]
 with tempfile.TemporaryDirectory(prefix='derived-mixed-gnu-') as td:
  for c in json.loads((R/'manifest.json').read_text())['cases']:
   s=R/c['source'];assert hashlib.sha256(s.read_bytes()).hexdigest()==c['sha256']
   work=Path(td)/c['name'];work.mkdir()
   p=execute([FC,'-std=f2018','-pedantic-errors','-fcheck=all',s,'-o',work/'oracle'],work)
   q=execute([work/'oracle'],work) if c['gnu_mode']=='execute' and p==dict(code=0,stdout='',stderr='') else None
   errors=oracle_check(c,s,p,q);rows.append(dict(name=c['name'],compile=p,run=q,errors=errors))
   assert hashlib.sha256(s.read_bytes()).hexdigest()==c['sha256']
   print(c['name'],'PASS' if not errors else errors,flush=True)
 result=dict(total=len(rows),failed=sum(bool(r['errors']) for r in rows),records=rows);args.results.write_text(json.dumps(result,indent=2)+'\n');return bool(result['failed'])
if __name__=='__main__':raise SystemExit(main())
