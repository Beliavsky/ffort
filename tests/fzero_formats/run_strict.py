#!/usr/bin/env python3
"""Read-only, hash-bound F0 checks; all success/error contracts are exact."""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent
class ContractError(Exception):pass
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def require(ok,message):
 if not ok:raise ContractError(message)
def verify(path,expected):
 require(len(expected)==64 and all(x in '0123456789abcdef' for x in expected),'invalid pinned SHA256')
 require(digest(path)==expected,'SHA256 mismatch: '+str(path))
def owned(relative):
 p=(ROOT/relative).resolve()
 require(p.is_relative_to(ROOT) and p!=ROOT,'fixture path escapes root')
 return p
def contract(result,code,stdout,stderr):
 require(type(result['status']) is int and result['status']>=0,'exit status must be a nonnegative integer')
 require(result['status']==code,'wrong exit status')
 require(bytes.fromhex(result['stdout_hex'])==stdout,'wrong stdout bytes')
 require(bytes.fromhex(result['stderr_hex'])==stderr,'wrong stderr bytes')
def invoke(command,cwd,identities):
 for path,sha in identities:verify(path,sha)
 try:
  p=subprocess.run([str(x) for x in command],cwd=cwd,capture_output=True,timeout=20)
  return dict(command=[str(x) for x in command],status=p.returncode,stdout_hex=p.stdout.hex(),stderr_hex=p.stderr.hex())
 except subprocess.TimeoutExpired as e:raise ContractError('20-second timeout: '+str(command[0])) from e
 finally:
  for path,sha in identities:verify(path,sha)
def run_case(row,args,temp,identities):
 p=owned(row['source']);verify(p,row['source_sha256'])
 stage=row['stage'];require(stage in ['success','static','runtime'],'unknown stage')
 expected=(owned(row['stdout']).read_bytes() if row['stdout'] is not None else b'')
 if row['stdout'] is not None:verify(owned(row['stdout']),row['stdout_sha256'])
 err=row['stderr'].replace('@SOURCE@',str(p)).encode()
 record=dict(name=row['name'],passed=False,operations=[])
 ids=identities+[(p,row['source_sha256'])]
 if row['stdout'] is not None:ids.append((owned(row['stdout']),row['stdout_sha256']))
 try:
  check=invoke([args.candidate,'--check',p],temp,ids);record['operations'].append(check)
  contract(check,1 if stage=='static' else 0,b'',err if stage=='static' else b'')
  actual=invoke([args.candidate,p],temp,ids);record['operations'].append(actual)
  contract(actual,{'success':0,'static':1,'runtime':2}[stage],expected,err)
  if stage=='success':
   exe=Path(temp)/'oracle'
   compile_result=invoke([args.gfortran,'-o',exe,p],temp,ids);record['operations'].append(compile_result)
   contract(compile_result,0,b'',b'')
   oracle=invoke([exe],temp,ids);record['operations'].append(oracle)
   contract(oracle,0,expected,b'')
  record['passed']=True
 except (ContractError,OSError) as e:record['error']=str(e)
 return record
def main():
 ap=argparse.ArgumentParser()
 for name in ['candidate','gfortran','compiler-binary','runtime-source','result']:ap.add_argument('--'+name,type=Path,required=True)
 for name in ['candidate-sha256','compiler-sha256','compiler-binary-sha256','runtime-sha256','manifest-sha256']:ap.add_argument('--'+name,required=True)
 a=ap.parse_args()
 for name in ['candidate','gfortran','compiler_binary','runtime_source','result']:setattr(a,name,getattr(a,name).resolve())
 unsafe_result=a.result.exists() or a.result.is_relative_to(ROOT) or a.result in {a.candidate,a.gfortran,a.compiler_binary,a.runtime_source}
 report=dict(status='failed',cases=[],source_core_status='candidate_under_test',identities={})
 try:
  require(not unsafe_result,'result must not overwrite fixtures or pinned inputs')
  identities=[(a.candidate,a.candidate_sha256),(a.gfortran,a.compiler_sha256),(a.compiler_binary,a.compiler_binary_sha256),(a.runtime_source,a.runtime_sha256),(ROOT/'manifest.json',a.manifest_sha256)]
  for p,h in identities:verify(p,h)
  report['identities']={str(p):h for p,h in identities}
  rows=json.loads((ROOT/'manifest.json').read_text())
  require(isinstance(rows,list) and len(rows)==40,'expected exactly40 maintained cases')
  require(len({r['name'] for r in rows})==len(rows),'duplicate case names')
  for row in rows:
   with tempfile.TemporaryDirectory(prefix='fzero-strict-case-') as temp:
    report['cases'].append(run_case(row,a,temp,identities))
  for p,h in identities:verify(p,h)
  report['passed']=sum(r['passed'] for r in report['cases']);report['failed']=len(rows)-report['passed']
  if report['failed']==0:report['status']='passed'
 except (ContractError,OSError,ValueError,KeyError,TypeError) as e:report['error']=str(e)
 # Never overwrite pinned source fixtures, even while reporting input failures.
 if unsafe_result:
  print(json.dumps(report,indent=2));return 1
 a.result.parent.mkdir(parents=True,exist_ok=True)
 with a.result.open('x') as output:output.write(json.dumps(report,indent=2)+'\n')
 print(json.dumps({k:v for k,v in report.items() if k!='cases'},indent=2))
 return 0 if report['status']=='passed' else 1
if __name__=='__main__':raise SystemExit(main())
