#!/usr/bin/env python3
"""Separate check/run and explicit GNU execution/compile-only/rejection evidence."""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent
CRASH=('backtrace','segmentation fault','internal compiler error','runtime error: index')
def run(argv,cwd=None):
 p=subprocess.run([str(a) for a in argv],cwd=cwd,capture_output=True,text=True,timeout=40)
 return dict(argv=[str(a) for a in argv],code=p.returncode,out=p.stdout,err=p.stderr)
def expected_diagnostic(case,source):
 d=case['diagnostic']
 return f"{source}:{d['line']}:{d['column']}: {d['message']}\n"
def errors(case,check,execution,source):
 bad=[];category=case['category']
 if any(t in (check['err']+execution['err']).lower() for t in CRASH):bad.append('host crash')
 if check['out']:bad.append('check wrote output')
 if category=='success':
  if check['code']!=0 or check['err']:bad.append('check failed/noisy')
  if execution['code']!=0 or execution['err'] or execution['out']!=case['expected_stdout']:bad.append('execution mismatch')
 elif category in ('reject','runtime'):
  d=case['diagnostic'];phase='source' if category=='reject' else 'runtime';status=1 if phase=='source' else 2
  if d['phase']!=phase or d['status']!=status:bad.append('manifest status/phase mismatch')
  exact=expected_diagnostic(case,source)
  if category=='reject':
   for label,result in [('check',check),('run',execution)]:
    if result['code']!=status or result['out'] or result['err']!=exact:bad.append(label+' exact source rejection mismatch')
  else:
   if check['code']!=0 or check['err']:bad.append('runtime case did not check cleanly')
   if execution['code']!=status or execution['out']!=case['expected_stdout'] or execution['err']!=exact:bad.append('exact runtime rejection mismatch')
 else:bad.append('unknown case category')
 return bad
def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--gfortran',default='gfortran');p.add_argument('--result',default='results.json');a=p.parse_args();exe=a.candidate.resolve();manifest=json.loads((ROOT/'manifest.json').read_text());records=[]
 with tempfile.TemporaryDirectory(prefix='repeat-oracle-') as td:
  td=Path(td)
  for c in manifest['cases']:
   src=ROOT/'cases'/f"{c['name']}.f90";check=run([exe,'--check',src]);executed=run([exe,src]);bad=errors(c,check,executed,str(src.resolve()))
   oracle=td/'oracle';compiled=run([a.gfortran,'-std=f2018','-pedantic-errors','-O0','-fcheck=all','-ffree-line-length-none',src,'-o',oracle],td);observed=None
   if c['oracle']=='reject':
    if compiled['code']==0 or any(x in compiled['err'].lower() for x in CRASH):bad.append('GNU did not reject source cleanly')
   elif compiled['code']!=0 or compiled['err']:bad.append('GNU compilation failed/noisy')
   elif c['oracle']=='execute':
    observed=run([oracle],td)
    if observed['code']!=0 or observed['err'] or observed['out']!=c['expected_stdout']:bad.append('GNU output mismatch')
   records.append(dict(name=c['name'],source_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),category=c['category'],expected_diagnostic=c.get('diagnostic'),oracle_mode=c['oracle'],check=check,run=executed,gnu_compile=compiled,gnu_run=observed,errors=bad));print(('PASS' if not bad else 'FAIL')+': '+c['name'],flush=True)
 summary=dict(total=len(records),failed=sum(bool(c['errors']) for c in records),gnu_executed=sum(c['gnu_run'] is not None for c in records),gnu_compile_only=sum(c['oracle_mode']=='compile' for c in records),gnu_rejections=sum(c['oracle_mode']=='reject' for c in records))
 result=dict(runner_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),candidate_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(),candidate_version=run([exe,'--version']),gnu_version=run([a.gfortran,'--version']),summary=summary,cases=records)
 path=Path(a.result);path=path if path.is_absolute() else ROOT/path;path.write_text(json.dumps(result,indent=2)+'\n');print(summary);return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
