#!/usr/bin/env python3
"""REAL trigonometric intrinsics: GNU differential and fail-closed source checks."""
import argparse,hashlib,json,math,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def run(cmd,cwd):
 r=subprocess.run([str(x) for x in cmd],cwd=cwd,text=True,capture_output=True,timeout=30)
 return dict(status=r.returncode,stdout=r.stdout,stderr=r.stderr)

def equal(a,b,rel_tol):
 a=a.lower().replace('d','e').split();b=b.lower().replace('d','e').split()
 if len(a)!=len(b):return False
 for x,y in zip(a,b):
  try:
   if not math.isclose(float(x),float(y),rel_tol=rel_tol,abs_tol=0.0):return False
  except ValueError:
   if x!=y:return False
 return True

def check_provenance():
 metadata=json.loads((ROOT/'utility-provenance.json').read_text())
 original=ROOT.parents[1]/metadata['source_file']
 raw=original.read_bytes()
 if hashlib.sha256(raw).hexdigest()!=metadata['source_sha256']:
  raise AssertionError('Original utility source hash changed')
 lines=raw.decode().replace('\r\n','\n').splitlines(keepends=True)
 fixture=(ROOT/'utility_sine.f90').read_text()
 for item in metadata['functions']:
  body=''.join(lines[item['first_line']-1:item['last_line']])
  if hashlib.sha256(body.encode()).hexdigest()!=item['body_sha256'] or fixture.count(body)!=1:
   raise AssertionError('Original utility body changed: '+item['name'])
 print('PASS: five utility bodies and original source provenance',flush=True)

def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--gfortran',default='gfortran');p.add_argument('--result',default='results.json');a=p.parse_args();a.candidate=a.candidate.resolve()
 check_provenance()
 cases=[]
 for name in ('scalars','arrays','unevaluated_kind','procedures','limits','utility_sine','real64_precision'):
  cases.append((name,(ROOT/(name+'.f90')).read_text(),'pass',''))
 for op in ('sin','cos','tan'):
  for label,expr,diag in [('integer',op+'(1)','Transcendental intrinsic requires REAL argument'),('logical',op+'(.true.)','Transcendental intrinsic requires REAL argument'),('character',op+"('x')",'Transcendental intrinsic requires REAL argument'),('empty',op+'()','Intrinsic requires one argument'),('excess',op+'(1.0,2.0)','Intrinsic requires one argument'),('unknown_keyword',op+'(a=1.0)','Unknown keyword or excess actual argument'),('duplicate',op+'(x=1.0,x=2.0)','Repeated actual argument'),('positional_after_keyword',op+'(x=1.0,2.0)','Positional argument cannot follow')]:
   cases.append((op+'_'+label,'program p\nprint *,'+expr+'\nend program\n','reject',diag))
 for op in ('sin','cos','tan'):
  for label,expr in [('complex',op+'((1.0,1.0))'),('real16',op+'(1.0_16)'),('legacy_alias','d'+op+'(1.0d0)')]:
   cases.append((op+'_'+label,'program p\nprint *,'+expr+'\nend program\n','unsupported',''))
  cases.append((op+'_undefined','program p\nreal :: x\nprint *,1,'+op+'(x)\nend program\n','runtime','uninitialized'))
 results=[]
 with tempfile.TemporaryDirectory(prefix='trigonometric-') as td:
  tmp=Path(td)
  for name,source,expected,diag in cases:
   src=tmp/(name+'.f90');src.write_text(source);exe=tmp/'oracle'
   g=run([a.gfortran,'-std=f2018','-fcheck=all',src,'-o',exe],tmp)
   o=run([exe],tmp) if g['status']==0 else None
   check=run([a.candidate,'--check',src],tmp);r=run([a.candidate,src],tmp)
   if expected=='pass':ok=g['status']==0 and o['status']==0 and check['status']==0 and not check['stdout'] and not check['stderr'] and r['status']==0 and not r['stderr'] and equal(r['stdout'],o['stdout'],1e-13 if name in ('real64_precision','utility_sine') else 1e-7)
   elif expected=='reject':ok=g['status']!=0 and check['status']==1 and r['status']==1 and not r['stdout'] and not check['stdout'] and diag in check['stderr'] and diag in r['stderr']
   elif expected=='unsupported':ok=g['status']==0 and check['status']==1 and r['status']==1 and not check['stdout'] and not r['stdout']
   else:ok=g['status']==0 and check['status']==0 and not check['stdout'] and not check['stderr'] and r['status']==2 and not r['stdout'] and diag.lower() in r['stderr'].lower()
   results.append(dict(name=name,expected=expected,pass_=ok,gfortran=g,oracle=o,check=check,candidate=r))
   print(('PASS' if ok else 'FAIL')+': '+name,flush=True)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(results),failed=sum(not c['pass_'] for c in results),cases=results)
 out=Path(a.result);out=out if out.is_absolute() else ROOT/out;out.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return bool(result['failed'])
if __name__=='__main__':raise SystemExit(main())
