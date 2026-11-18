from pathlib import Path
from decimal import Decimal
import argparse,json,subprocess,hashlib,tempfile,re
from contracts import check
R=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--results',type=Path,default=R/'candidate-results.json');a=ap.parse_args();cli=a.candidate.resolve();digest=hashlib.sha256(cli.read_bytes()).hexdigest();rows=[]
with tempfile.TemporaryDirectory(prefix='derived-mixed-candidate-') as td:
 for c in json.loads((R/'manifest.json').read_text())['cases']:
  source=R/c['source'];assert hashlib.sha256(source.read_bytes()).hexdigest()==c['sha256'];row=dict(name=c['name']);errors=[]
  for stage,extra in [('check',['--check']),('run',[])]:
   try:
    p=subprocess.run([str(cli),*extra,str(source)],cwd=td,capture_output=True,text=True,timeout=30);r=dict(code=p.returncode,stdout=p.stdout,stderr=p.stderr)
   except subprocess.TimeoutExpired:r=dict(code=None,stdout='',stderr='TIMEOUT')
   row[stage]=r
   if re.search('TIMEOUT|backtrace|segmentation|runtime error|SIGSEGV',r['stdout']+r['stderr'],re.I):errors.append(stage+' crash')
  errors=check(c,source,row)
  row['errors']=errors;rows.append(row);print(c['name'],'PASS' if not errors else errors,flush=True)
assert hashlib.sha256(cli.read_bytes()).hexdigest()==digest
result=dict(candidate=str(cli),sha256=digest,total=len(rows),failed=sum(bool(r['errors']) for r in rows),records=rows);a.results.write_text(json.dumps(result,indent=2)+'\n');raise SystemExit(bool(result['failed']))
