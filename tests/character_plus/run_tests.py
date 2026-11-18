#!/usr/bin/env python3
"""Exact output bytes and separate, explicitly scoped GNU O0 alias evidence."""
import argparse,hashlib,json,re,subprocess,tempfile
from pathlib import Path
from check_provenance import check as check_provenance
ROOT=Path(__file__).resolve().parent

def run(args,cwd):
 p=subprocess.run([str(x) for x in args],cwd=cwd,capture_output=True,timeout=60)
 return dict(status=p.returncode,stdout=p.stdout.decode(),stderr=p.stderr.decode())

def successful_check(result):
 return result['status']==0 and not result['stdout'] and not result['stderr']

def output_matches(actual,reference,case):
 return actual==reference and ('stdout' not in case or actual==case['stdout'])

def known_o0_observation(result,case):
 return result is not None and result['status']==0 and not result['stderr'] and result['stdout'] in (case['stdout'],case['gnu_o0_discrepancy'])

def main():
 check_provenance()
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',type=Path,default=ROOT/'results.json');a=ap.parse_args();a.candidate=a.candidate.resolve();records=[]
 with tempfile.TemporaryDirectory(prefix='character-plus-') as temp:
  temp=Path(temp)
  for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
   p=ROOT/(case['name']+'.f90');assert hashlib.sha256(p.read_bytes()).hexdigest()==case['sha256']
   check=run([a.candidate,'--check',p],temp);actual=run([a.candidate,p],temp)
   compile=run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow',p,'-o',temp/'oracle'],temp);oracle=None
   if case['kind']=='pass':
    if compile['status']==0:oracle=run([temp/'oracle'],temp)
    o0=None
    if 'gnu_o0_discrepancy' in case and oracle is not None:
     o0=oracle
     optimized_compile=run([a.gfortran,'-O2','-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow',p,'-o',temp/'oracle-o2'],temp)
     oracle=run([temp/'oracle-o2'],temp) if optimized_compile['status']==0 else None
    ok=successful_check(check) and actual['status']==0 and not actual['stderr'] and oracle is not None and oracle['status']==0 and not oracle['stderr'] and output_matches(actual['stdout'],oracle['stdout'],case)
   else:
    status=1 if case['kind']=='reject' else 2
    ok=(check['status']==1 and not check['stdout'] and bool(check['stderr'])) if status==1 else successful_check(check)
    ok=ok and actual['status']==status and actual['stdout']==case.get('prefix','') and bool(actual['stderr']) and case['diagnostic_contains'].lower() in actual['stderr'].lower()
   if case['kind']=='pass' and 'gnu_o0_discrepancy' in case:
    ok=ok and known_o0_observation(o0,case)
   ok=ok and (compile['status']==0 if case['gnu_compile']=='pass' else compile['status']==1)
   ok=ok and 'Backtrace' not in actual['stderr'] and 'Fortran runtime error' not in actual['stderr']
   records.append(dict(**case,passed=bool(ok),check=check,actual=actual,compile=compile,oracle=oracle,gnu_o0=o0 if case['kind']=='pass' else None))
   print(('PASS: ' if ok else 'FAIL: ')+case['name'],flush=True)
   if not ok:print(repr(dict(check=check,actual=actual,compile=compile))[:1500],flush=True)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(records),failed=sum(not c['passed'] for c in records),cases=records)
 a.result.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
