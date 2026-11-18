#!/usr/bin/env python3
"""REAL rounding and LOG10 intrinsics: GNU differential and fail-closed source checks."""
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
  if re.fullmatch(r'[+-]?\d+',x) and re.fullmatch(r'[+-]?\d+',y):
   if int(x)!=int(y):return False
   continue
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
 fixture=(ROOT/'utility_rounding.f90').read_text()
 for item in metadata['functions']:
  body=''.join(lines[item['first_line']-1:item['last_line']])
  if hashlib.sha256(body.encode()).hexdigest()!=item['body_sha256'] or fixture.count(body)!=1:
   raise AssertionError('Original utility body changed: '+item['name'])
 print('PASS: two utility bodies and original source provenance',flush=True)

def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--gfortran',default='gfortran');p.add_argument('--result',default='results.json');a=p.parse_args();a.candidate=a.candidate.resolve()
 check_provenance()
 cases=[]
 for name in ('scalars','arrays','boundaries','procedures','inquiries','utility_rounding','sweep'):
  cases.append((name,(ROOT/(name+'.f90')).read_text(),'pass',''))
 for op in ('nint','floor','ceiling'):
  for label,expr,diag in [('integer',op+'(1)','Rounding intrinsic requires REAL'),('logical',op+'(.true.)','Rounding intrinsic requires REAL'),('character',op+"('x')",'Rounding intrinsic requires REAL'),('empty',op+'()','requires one or two'),('excess',op+'(1.0,4,8)','requires one or two'),('unknown_keyword',op+'(x=1.0)','Unknown keyword'),('duplicate',op+'(a=1.0,a=2.0)','Repeated actual'),('positional_after_keyword',op+'(a=1.0,4)','Positional argument'),('real_kind',op+'(1.0,kind=4.0)','scalar INTEGER'),('array_kind',op+'(1.0,kind=[4])','scalar INTEGER')]:
   cases.append((op+'_'+label,'program p\nprint *,'+expr+'\nend program\n','reject',diag))
  cases.append((op+'_variable_kind','program p\ninteger::k=4\nprint *,'+op+'(1.0,kind=k)\nend program\n','reject','constant'))
  for label,expr in [('real16',op+'(1.0_16)'),('kind1',op+'(1.0,kind=1)'),('kind2',op+'(1.0,kind=2)'),('kind16',op+'(1.0,kind=16)')]:
   cases.append((op+'_'+label,'program p\nprint *,'+expr+'\nend program\n','unsupported',''))
  cases.append((op+'_undefined','program p\nreal :: x\nprint *,1,'+op+'(x)\nend program\n','runtime','uninitialized'))
  for label,value,kind in [('positive32','2147483648.0d0',4),('negative32','-2147483649.0d0',4),('positive64','9223372036854775808.0d0',8),('negative64','-9223372036854777856.0d0',8)]:
   cases.append((op+'_overflow_'+label,'program p\nreal(8)::x='+value+'\nprint *,1,'+op+'(x,kind='+str(kind)+')\nend program\n','runtime','overflow'))
 for label,expr,diag in [('integer','log10(1)','requires REAL'),('logical','log10(.true.)','requires REAL'),('character',"log10('a')",'requires REAL'),('empty','log10()','requires one'),('excess','log10(1.0,2.0)','requires one'),('keyword','log10(a=1.0)','Unknown keyword'),('duplicate','log10(x=1.0,x=2.0)','Repeated actual')]:
  cases.append(('log10_'+label,'program p\nprint *,'+expr+'\nend program\n','reject',diag))
 for value in ('0.0d0','-1.0d0'):
  cases.append(('log10_domain_'+value,'program p\nreal(8)::x='+value+'\nprint *,1,log10(x)\nend program\n','runtime','positive'))
 cases.append(('log10_real16','program p\nprint *,log10(1.0_16)\nend program\n','unsupported',''))
 cases.append(('log10_alias','program p\nprint *,dlog10(1.0d0)\nend program\n','unsupported',''))
 results=[]
 with tempfile.TemporaryDirectory(prefix='trigonometric-') as td:
  tmp=Path(td)
  for name,source,expected,diag in cases:
   src=tmp/(name+'.f90');src.write_text(source);exe=tmp/'oracle'
   g=run([a.gfortran,'-std=f2018','-fcheck=all',src,'-o',exe],tmp)
   o=run([exe],tmp) if g['status']==0 and expected=='pass' else None
   check=run([a.candidate,'--check',src],tmp);r=run([a.candidate,src],tmp)
   if expected=='pass':ok=g['status']==0 and o['status']==0 and check['status']==0 and not check['stdout'] and not check['stderr'] and r['status']==0 and not r['stderr'] and equal(r['stdout'],o['stdout'],1e-13 if name=='utility_rounding' else 1e-7)
   elif expected=='reject':ok=g['status']!=0 and check['status']==1 and r['status']==1 and not r['stdout'] and not check['stdout'] and diag in check['stderr'] and diag in r['stderr']
   elif expected=='unsupported':ok=g['status']==0 and check['status']==1 and r['status']==1 and not check['stdout'] and not r['stdout']
   else:ok=g['status']==0 and check['status']==0 and not check['stdout'] and not check['stderr'] and r['status']==2 and not r['stdout'] and diag.lower() in r['stderr'].lower()
   results.append(dict(name=name,expected=expected,pass_=ok,gfortran=g,oracle=o,check=check,candidate=r))
   print(('PASS' if ok else 'FAIL')+': '+name,flush=True)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(results),failed=sum(not c['pass_'] for c in results),cases=results)
 out=Path(a.result);out=out if out.is_absolute() else ROOT/out;out.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return bool(result['failed'])
if __name__=='__main__':raise SystemExit(main())
