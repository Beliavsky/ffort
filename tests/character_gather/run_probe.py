import pathlib,json,subprocess,tempfile,os,hashlib,argparse
ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True);ap.add_argument('--output',required=True);ap.add_argument('--run',action='store_true');ap.add_argument('--gfortran',default='gfortran');a=ap.parse_args()
r=pathlib.Path(__file__).parent/'tests';env=dict(os.environ);records=[];candidate=pathlib.Path(a.candidate).resolve();before=hashlib.sha256(candidate.read_bytes()).hexdigest()
def run(cmd,cwd=None):
 p=subprocess.run(cmd,capture_output=True,text=True,env=env,timeout=30,cwd=cwd);return {'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
for c in json.loads((r/'manifest.json').read_text())['cases']:
 src=(r/c['source']).resolve();rec=dict(c);rec['check']=run([str(candidate),'--check',str(src)])
 if a.run and rec['check']['status']==0:rec['candidate_run']=run([str(candidate),str(src)])
 with tempfile.TemporaryDirectory(prefix='gather-gnu-',dir='/tmp')as d:
  rec['gnu_compile']=run([a.gfortran,'-std=f2018','-fcheck=all',str(src),'-o',d+'/a.out','-J',d],cwd=d)
  if rec['gnu_compile']['status']==0 and c['mode']=='run':rec['gnu_run']=run([d+'/a.out'],cwd=d)
 records.append(rec);print(c['name'],rec['check']['status'],rec.get('candidate_run',{}).get('status'),rec['gnu_compile']['status'],flush=True)
pathlib.Path(a.output).write_text(json.dumps({'candidate_sha256':before,'candidate_sha256_after':hashlib.sha256(candidate.read_bytes()).hexdigest(),'records':records},indent=2)+'\n')
