#!/usr/bin/env python3
"""Exact LEADZ source/GNU checks; candidate execution only when explicitly supplied."""
import argparse,hashlib,json,os,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path);p.add_argument('--gfortran',type=Path);p.add_argument('--result',type=Path,default=ROOT/'results.json');a=p.parse_args()
if not a.candidate and not a.gfortran:p.error('Specify --candidate and/or --gfortran')
def execute(args,cwd=None):
 try:
  r=subprocess.run(list(map(str,args)),text=True,capture_output=True,stdin=subprocess.DEVNULL,timeout=20,cwd=cwd or ROOT)
  return {'command':list(map(str,args)),'returncode':r.returncode,'stdout':r.stdout,'stderr':r.stderr,'timeout':False}
 except subprocess.TimeoutExpired as e:return {'command':list(map(str,args)),'returncode':None,'stdout':e.stdout or '', 'stderr':e.stderr or '', 'timeout':True}
def matches(case,output):
 if case.get('byte_exact'):return output==case['expected_stdout']
 return output.split()==case['expected_tokens']
rows=[]
for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
 source=ROOT/case['source'];assert hashlib.sha256(source.read_bytes()).hexdigest()==case['sha256']
 r={'case':case,'errors':[]}
 if a.gfortran:
  with tempfile.TemporaryDirectory(prefix='leadz-gnu-',dir=ROOT) as temp:
   exe=Path(temp)/'test';compiled=execute([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffree-line-length-none','-O0',source,'-o',exe],cwd=temp);r['native_compile']=compiled
   want=1 if case['gnu']=='reject' else 0
   if compiled['returncode']!=want or compiled['timeout'] or compiled['stdout'] or (want and not compiled['stderr']):r['errors'].append('GNU compile outcome')
   if case['gnu']=='execute' and compiled['returncode']==0:
    ran=execute([exe],cwd=temp);r['native_run']=ran
    if ran['returncode']!=0 or ran['timeout'] or ran['stderr'] or not matches(case,ran['stdout']):r['errors'].append('GNU execution/independent output mismatch')
 if a.candidate:
  check=execute([a.candidate,'--check',source]);ran=execute([a.candidate,source]);r.update(check=check,interpreter_run=ran)
  check_code=1 if case['stage']=='check' else 0;run_code={'check':1,'runtime':2,'success':0}[case['stage']]
  if check['returncode']!=check_code or check['stdout'] or check['timeout'] or (check_code==0 and check['stderr']):r['errors'].append('candidate check outcome')
  if ran['returncode']!=run_code or ran['timeout'] or (run_code==0 and ran['stderr']) or (run_code!=0 and not ran['stderr']):r['errors'].append('candidate run outcome')
  if not matches(case,ran['stdout']):r['errors'].append('candidate output mismatch/leak')
  if case.get('diagnostic') and case['diagnostic'].lower() not in ran['stderr'].lower():r['errors'].append('candidate diagnostic')
  if 'backtrace' in ran['stderr'].lower() or 'sigsegv' in ran['stderr'].lower():r['errors'].append('candidate crash')
 rows.append(r)
summary={'cases':len(rows),'failed':sum(bool(r['errors']) for r in rows),'candidate_executed':bool(a.candidate),'gnu_checked':bool(a.gfortran),'candidate_sha256':hashlib.sha256(a.candidate.read_bytes()).hexdigest() if a.candidate else None,'gnu_version':execute([a.gfortran,'--version'])['stdout'].splitlines()[0] if a.gfortran else None,'results':rows}
a.result.write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k!='results'},indent=2))
for r in rows:
 if r['errors']:print(r['case']['name'],r['errors'])
raise SystemExit(bool(summary['failed']))
