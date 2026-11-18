import json,pathlib,subprocess,tempfile,hashlib,sys
w=pathlib.Path(__file__).resolve().parent;cc=sys.argv[1];rows=[];failed=[]
def execute(argv,cwd,timeout):
 try:return subprocess.run(argv,cwd=cwd,text=True,capture_output=True,timeout=timeout)
 except subprocess.TimeoutExpired as e:
  return subprocess.CompletedProcess(argv,-999,stdout=str(e.stdout or ''),stderr='TIMEOUT '+str(e.stderr or ''))
for x in json.loads((w/'manifest.json').read_text()):
 p=w/'tests'/(x['name']+'.f90');r={'name':x['name'],'errors':[]};assert hashlib.sha256(p.read_bytes()).hexdigest()==x['source_sha256']
 with tempfile.TemporaryDirectory() as td:
  z=execute([cc,'-std=f2018','-pedantic-errors','-fcheck=all',str(p),'-o',td+'/a'],td,20);r['compile']={'code':z.returncode,'stdout':z.stdout,'stderr':z.stderr}
  expect=1 if x['gnu_mode']=='reject' else 0
  if z.returncode!=expect or any(t in z.stderr.lower() for t in ('internal compiler error','segmentation fault','backtrace:')):r['errors'].append('compile')
  if x['gnu_mode']=='reject' and (not z.stderr or z.stdout):r['errors'].append('reject streams')
  if x['gnu_mode']=='run' and z.returncode==0:
   z=execute([td+'/a'],td,5);r['run']={'code':z.returncode,'stdout':z.stdout,'stderr':z.stderr}
   equal=([list(map(int,l.split())) for l in z.stdout.splitlines()]==x['records'] and z.stdout.endswith('\n')) if 'records' in x else z.stdout==x['stdout']
   if z.returncode or z.stderr or not equal:r['errors'].append('run')
 rows.append(r)
 if r['errors']:failed.append(x['name'])
 (w/'gnu-results.json').write_text(json.dumps({'cases':rows,'failed':failed},indent=2)+'\n')
print('PASS' if not failed else 'FAIL',len(rows),failed);raise SystemExit(bool(failed))
