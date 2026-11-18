import json,pathlib,subprocess,hashlib,argparse
w=pathlib.Path(__file__).resolve().parent;ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True);ap.add_argument('--result',required=True);ap.add_argument('--observe',action='store_true');args=ap.parse_args();exe=str(pathlib.Path(args.candidate).resolve());digest=hashlib.sha256(pathlib.Path(exe).read_bytes()).hexdigest();rows=[];failed=[]
for x in json.loads((w/'manifest.json').read_text()):
 p=w/'tests'/(x['name']+'.f90');r={'name':x['name'],'source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'errors':[]}
 if r['source_sha256']!=x['source_sha256']:r['errors'].append('source hash mismatch; execution withheld')
 else:
  for phase,argv in [('check',[exe,'--check',str(p)]),('run',[exe,'--max-steps','500',str(p)])]:
   try:
    z=subprocess.run(argv,capture_output=True,text=True,timeout=15);r[phase]={'code':z.returncode,'stdout':z.stdout,'stderr':z.stderr}
   except subprocess.TimeoutExpired as z:r[phase]={'timeout':True,'stdout':str(z.stdout),'stderr':str(z.stderr)}
   q=r[phase];expected=1 if x['mode']=='reject' else 2 if phase=='run' and x['mode']!='run' else 0
   if q.get('code')!=expected:r['errors'].append(phase+' status')
   if expected==0 and q.get('stderr'):r['errors'].append(phase+' stderr')
   if phase=='check' or x['mode']!='run':
    if q.get('stdout'):r['errors'].append(phase+' stdout leak')
   else:
    try:equal=([list(map(int,l.split())) for l in q.get('stdout','').splitlines()]==x['records'] and q.get('stdout','').endswith('\n')) if 'records' in x else q.get('stdout')==x['stdout']
    except ValueError:equal=False
    if not equal:r['errors'].append('run output')
   if expected:
    if args.observe:
     if not q.get('stderr'):r['errors'].append(phase+' missing diagnostic')
    elif q.get('stderr')!=x['diagnostic'].replace('{source}',str(p)):r['errors'].append(phase+' diagnostic')
 rows.append(r)
 if r['errors']:failed.append(x['name'])
 pathlib.Path(args.result).write_text(json.dumps({'executable_sha256':digest,'observation_only':args.observe,'cases':rows,'failed':failed},indent=2)+'\n')
assert digest==hashlib.sha256(pathlib.Path(exe).read_bytes()).hexdigest()
print('PASS' if not failed else 'FAIL',len(rows),failed);raise SystemExit(bool(failed))
