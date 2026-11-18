#!/usr/bin/env python3
"""Exact immutable-source/check/run and explicitly separated GNU oracle stages."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
CRASH=('backtrace','segmentation fault','internal compiler error','runtime error: index')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def run(args,cwd=None):
 p=subprocess.run([str(x)for x in args],cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=60,env=dict(os.environ,LC_ALL='C'))
 return {'argv':[str(x)for x in args],'status':p.returncode,'stdout':p.stdout.decode('latin1'),'stderr':p.stderr.decode('latin1')}
def diagnostic(case,source):
 d=case['diagnostic'];return f"{source}:{d['line']}:{d['column']}: {d['message']}\n"
def errors(case,check,execution,source):
 bad=[];category=case['category']
 if any(t in (check['stderr']+execution['stderr']).lower()for t in CRASH):bad.append('host crash')
 if check['stdout']:bad.append('check wrote output')
 if category=='success':
  if check['status']!=0 or check['stderr']:bad.append('check failed/noisy')
  if execution['status']!=0 or execution['stderr'] or execution['stdout']!=case['expected_stdout']:bad.append('exact execution mismatch')
 elif category in ('reject','runtime'):
  d=case['diagnostic'];phase='source'if category=='reject'else'runtime';status=1 if category=='reject'else 2
  if d['phase']!=phase or d['status']!=status:bad.append('manifest phase/status mismatch')
  expected=diagnostic(case,source)
  if category=='reject':
   for label,q in [('check',check),('run',execution)]:
    if q['status']!=status or q['stdout'] or q['stderr']!=expected:bad.append(label+' exact source diagnostic mismatch')
  else:
   if check['status']!=0 or check['stderr']:bad.append('runtime case did not check cleanly')
   if execution['status']!=status or execution['stdout']!=case['expected_stdout'] or execution['stderr']!=expected:bad.append('exact runtime diagnostic mismatch')
 else:bad.append('unknown case category')
 return bad
def gnu_errors(case,result,source):
 if any(t in result['stderr'].lower()for t in CRASH):return ['GNU crash']
 if case['oracle']=='reject':return []if result['status']==1 and not result['stdout']else['GNU source rejection mismatch']
 wanted=case.get('gnu_compile_stderr','').replace('{source}',source)
 return []if result['status']==0 and result['stdout']=='' and result['stderr']==wanted else['GNU compilation/diagnostic mismatch']
def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--gfortran',default='gfortran');p.add_argument('--result',type=Path,default=ROOT/'results.json');a=p.parse_args();exe=a.candidate.resolve();before=sha(exe);m=json.loads((ROOT/'manifest.json').read_text());rows=[]
 with tempfile.TemporaryDirectory(prefix='write-element-verified-')as td:
  for c in m['cases']:
   src=(ROOT/'cases'/f"{c['name']}.f90").resolve();source_hash=sha(src)
   if source_hash!=c['source_sha256']:raise SystemExit('Fixture identity changed: '+c['name'])
   check=run([exe,'--check',src]);execution=run([exe,src]);bad=errors(c,check,execution,str(src));binary=Path(td)/'oracle';compiled=run([a.gfortran,'-std=f2018','-pedantic-errors','-O0','-fcheck=all','-ffree-line-length-none',src,'-o',binary],td);bad+=gnu_errors(c,compiled,str(src));oracle=None
   if c['oracle']=='execute' and compiled['status']==0:
    oracle=run([binary],td)
    if oracle['status']!=0 or oracle['stderr'] or oracle['stdout']!=c['expected_stdout']:bad.append('GNU exact execution mismatch')
   if sha(src)!=source_hash:bad.append('source changed during verification')
   rows.append({'name':c['name'],'source_sha256':source_hash,'category':c['category'],'expected_diagnostic':c.get('diagnostic'),'oracle_mode':c['oracle'],'check':check,'run':execution,'gnu_compile':compiled,'gnu_run':oracle,'errors':bad});print(('FAIL 'if bad else'PASS ')+c['name'],flush=True)
 after=sha(exe);summary={'total':len(rows),'failed':sum(bool(x['errors'])for x in rows),'gnu_executed':sum(x['gnu_run']is not None for x in rows),'gnu_compile_only':sum(x['oracle_mode']=='compile'for x in rows),'gnu_expected_reject':sum(x['oracle_mode']=='reject'for x in rows)}
 report={'candidate_sha256_before':before,'candidate_sha256_after':after,'candidate_version':run([exe,'--version']),'gnu_version':run([a.gfortran,'--version']),'runner_sha256':sha(Path(__file__)),'manifest_sha256':sha(ROOT/'manifest.json'),'summary':summary,'cases':rows};a.result.write_text(json.dumps(report,indent=2)+'\n');print(summary);return before!=after or bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
