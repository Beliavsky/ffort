"""Strict maintained source/GNU stages for bounded bare CHARACTER gather actuals."""
from pathlib import Path
import argparse,sys,hashlib,json,subprocess,tempfile,os
R=Path(__file__).resolve().parent
sys.path.insert(0,str(R))
from strict_contract import candidate_errors,gnu_errors,stage_errors,version_errors
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def run(cmd,cwd=None):
 try:
  q=subprocess.run(list(map(str,cmd)),capture_output=True,text=True,timeout=45,cwd=cwd,env=dict(os.environ,LC_ALL='C'));return dict(argv=list(map(str,cmd)),status=q.returncode,stdout=q.stdout,stderr=q.stderr)
 except subprocess.TimeoutExpired as e:return dict(argv=list(map(str,cmd)),status=None,stdout=str(e.stdout),stderr='TIMEOUT '+str(e.stderr),timeout=True)
def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--expected-sha',required=True);p.add_argument('--gfortran',required=True);p.add_argument('--result',type=Path,required=True);a=p.parse_args()
 exe=a.candidate.resolve();before=sha(exe)
 if before!=a.expected_sha:raise SystemExit('Wrong candidate identity')
 m=json.loads((R/'manifest.json').read_text());cases=m['cases'];neg=json.loads((R/'expectations.json').read_text());expected={c['name']for c in cases}
 if len(expected)!=len(cases)or len({c['source']for c in cases})!=len(cases):raise SystemExit('Duplicate source/expectation identity')
 if set(neg)!={c['name']for c in cases if c['category']!='success'}:raise SystemExit('Negative expectation inventory differs')
 if {p.name for p in(R/'cases').glob('*.f90')}!={Path(c['source']).name for c in cases}:raise SystemExit('Fixture inventory differs')
 version=run([exe,'--version']);rows=[]
 for original in cases:
  c=dict(original);src=(R/c['source']).resolve()
  if sha(src)!=c['sha256']:raise SystemExit('Fixture identity differs: '+c['name'])
  if c['name']in neg:c['diagnostic']=neg[c['name']]
  check=run([exe,'--check',src]);ran=run([exe,src]);errors=candidate_errors(c,check,ran,str(src));oracle=None
  with tempfile.TemporaryDirectory(prefix='bare-character-actual-strict-')as td:
   out=Path(td)/'oracle';compiled=run([a.gfortran,'-std=f2018','-pedantic-errors','-O0','-fcheck=all','-ffpe-trap=invalid,zero,overflow','-ffree-line-length-none',src,'-o',out],td)
   if c['gnu']=='run'and not stage_errors(compiled,'GNU compile') and compiled['status']==0:oracle=run([out],td)
   errors+=gnu_errors(c,compiled,oracle,str(src))
  if sha(src)!=c['sha256']:errors.append('Source changed during test')
  rows.append(dict(**c,check=check,run=ran,gnu_compile=compiled,gnu_run=oracle,errors=errors));print(('FAIL 'if errors else'PASS ')+c['name'],flush=True)
  if errors:print(errors,flush=True)
 after=sha(exe);version_after=run([exe,'--version']);gnu_version=run([a.gfortran,'--version']);identity=[]
 identity+=version_errors(version,'fortfront-interpreter ','candidate version before')
 identity+=version_errors(version_after,'fortfront-interpreter ','candidate version after')
 identity+=version_errors(gnu_version,'GNU Fortran','GNU version')
 if before!=after:identity.append('Candidate identity changed')
 if version!=version_after:identity.append('Candidate version changed')
 report=dict(candidate_sha256_before=before,candidate_sha256_after=after,version_before=version,version_after=version_after,gnu_version=gnu_version,manifest_sha256=sha(R/'manifest.json'),expectations_sha256=sha(R/'expectations.json'),runner_sha256=sha(Path(__file__)),total=len(rows),failed=sum(bool(r['errors'])for r in rows)+len(identity),identity_errors=identity,gnu_executed=sum(r['gnu_run']is not None for r in rows),gnu_compile_only=sum(r['gnu']=='compile'for r in rows),gnu_source_reject=sum(r['gnu']=='reject'for r in rows),records=rows)
 a.result.write_text(json.dumps(report,indent=2)+'\n');print({k:report[k]for k in ['total','failed','gnu_executed','gnu_compile_only','gnu_source_reject']});return bool(report['failed'])
if __name__=='__main__':raise SystemExit(main())
