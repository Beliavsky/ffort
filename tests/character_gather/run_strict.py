import argparse,hashlib,json,pathlib,subprocess,sys
root=pathlib.Path(__file__).resolve().parent
sys.path.insert(0,str(root/'tests'))
from strict_contract import check_record
ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=pathlib.Path);ap.add_argument('--expected-sha',required=True);ap.add_argument('--output',required=True,type=pathlib.Path);ap.add_argument('--gfortran',default='gfortran');a=ap.parse_args()
manifest=json.loads((root/'tests/manifest.json').read_text())['cases'];expectations=json.loads((root/'tests/expectations.json').read_text())
def require(condition,message):
 if not condition:raise SystemExit(message)
require(len({c['name'] for c in manifest})==len(manifest),'duplicate manifest names')
require(len({c['source'] for c in manifest})==len(manifest),'duplicate manifest sources')
require(set(expectations)=={c['name']for c in manifest},'expectation names differ')
for c in manifest:require(hashlib.sha256((root/'tests'/c['source']).read_bytes()).hexdigest()==c['sha256'],c['name']+' source differs')
require(hashlib.sha256(a.candidate.read_bytes()).hexdigest()==a.expected_sha,'candidate identity differs')
p=subprocess.run([sys.executable,str(root/'run_probe.py'),'--candidate',str(a.candidate),'--output',str(a.output),'--run','--gfortran',a.gfortran])
if p.returncode:raise SystemExit(p.returncode)
r=json.loads(a.output.read_text());errors=[]
require(r['candidate_sha256']==r['candidate_sha256_after']==a.expected_sha,'candidate changed')
require(hashlib.sha256(a.candidate.read_bytes()).hexdigest()==a.expected_sha,'candidate file changed')
rows=r['records'];expected={c['name']:c for c in manifest}
require(len(rows)==len(manifest),'record count differs')
require(len({row['name'] for row in rows})==len(rows),'duplicate record names')
require({row['name'] for row in rows}==set(expected),'record names differ')
for row in rows:
 c=expected[row['name']]
 require(all(row.get(k)==c[k] for k in ('source','sha256','mode')),'record metadata differs: '+row['name'])
for row in r['records']:
 source=str((root/'tests'/row['source']).resolve());e=check_record(row,expectations[row['name']],source)
 if row['gnu_compile']['status']!=0:e.append('GNU compile failed')
 if row['mode']=='run':
  if row.get('gnu_run',{}).get('status')!=0 or row['gnu_run']['stderr']!='':e.append('GNU execution failed')
  elif row['gnu_run']['stdout']!=expectations[row['name']]['gnu_stdout']:e.append('GNU stdout drift')
 row['errors']=e;errors.extend((row['name'],s)for s in e)
r.update(total=len(r['records']),failed=len([row for row in r['records']if row['errors']]),errors=errors)
a.output.write_text(json.dumps(r,indent=2)+'\n');print('total',r['total'],'failed',r['failed']);raise SystemExit(bool(errors))
