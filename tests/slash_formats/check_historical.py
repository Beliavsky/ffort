"""Strict success contracts for five unchanged pre-0.49 slash fixtures."""
from pathlib import Path
import argparse,hashlib,json,tempfile
from run_tests import run,candidate_errors,gnu_errors,FLAGS
R=Path(__file__).resolve().parent
ROOT=R.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--gfortran',required=True);p.add_argument('--result',type=Path,default=R/'historical-results.json');a=p.parse_args();a.candidate=a.candidate.resolve();identity=sha(a.candidate);rows=[]
 with tempfile.TemporaryDirectory(prefix='slash-historical-') as tmp:
  for case in json.loads((R/'historical_promotions.json').read_text())['cases']:
   source=ROOT/case['source'];assert sha(source)==case['sha256']
   check=run([a.candidate,'--check',source],tmp);ran=run([a.candidate,source],tmp)
   compiled=run([a.gfortran,*FLAGS,source,'-o',Path(tmp)/'reference'],tmp)
   reference=run([Path(tmp)/'reference'],tmp) if compiled==dict(code=0,out='',err='') else None
   errors=candidate_errors(case,check,ran,source)+gnu_errors(case,compiled,reference)
   assert sha(source)==case['sha256'];rows.append(dict(case=case,check=check,run=ran,gnu_compile=compiled,gnu_run=reference,errors=errors));print(case['source'],errors or 'PASS')
 assert sha(a.candidate)==identity
 report=dict(candidate_sha256=identity,total=len(rows),failed=sum(bool(r['errors']) for r in rows),records=rows);a.result.write_text(json.dumps(report,indent=2)+'\n');return bool(report['failed'])
if __name__=='__main__':raise SystemExit(main())
