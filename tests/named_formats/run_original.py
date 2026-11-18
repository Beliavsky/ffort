#!/usr/bin/env python3
"""Exact unchanged-source boundaries, plus optional joint ASIN execution proof."""
from pathlib import Path
import argparse,json,subprocess,tempfile,hashlib
from check_provenance import check
ROOT=Path(__file__).resolve().parent

def run(args,cwd):
 p=subprocess.run([str(a) for a in args],cwd=cwd,capture_output=True,text=True,timeout=60)
 return dict(status=p.returncode,stdout=p.stdout,stderr=p.stderr)

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--combined-asin',action='store_true');ap.add_argument('--result',type=Path,default=ROOT/'original-results.json');a=ap.parse_args();a.candidate=a.candidate.resolve();provenance=check();rows=[]
 with tempfile.TemporaryDirectory(prefix='named-format-original-') as temp:
  temp=Path(temp)
  for c in provenance['files']:
   src=ROOT/c['file'];q=run([a.candidate,'--check',src],temp);r=run([a.candidate,src],temp)
   flags=['-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow']
   if c['name']=='demo_nearest':
    # This unchanged original deliberately computes NEAREST(HUGE,+1), outside
    # the finite interpreter contract. GNU is run without FP traps and with
    # its explicit constant-overflow option only to verify preceding records.
    # Its overflowing record is never a reference for successful execution.
    flags=['-std=f2018','-pedantic-errors','-fcheck=all','-fno-range-check']
   comp=run([a.gfortran,*flags,src,'-o',temp/'oracle'],temp);ref=None
   if c['stage']=='reject':
    ok=q['status']==1 and not q['stdout'] and r['status']==1 and not r['stdout'] and c['diagnostic_contains'] in r['stderr']
    outcome='unchanged_original_later_source_boundary'
   elif c['stage']=='runtime':
    if comp['status']==0:ref=run([temp/'oracle'],temp)
    ok=q==dict(status=0,stdout='',stderr='') and r['status']==2 and c['diagnostic_contains'] in r['stderr'] and bool(r['stdout']) and ref is not None and ref['status']==0 and not ref['stderr'] and ref['stdout'].startswith(r['stdout'])
    ok=ok and 'For HUGE()' not in r['stdout'] and 'For TINY()' in r['stdout']
    outcome='unchanged_original_finite_runtime_boundary_prior_records_exact'
   elif c['stage']=='success' or a.combined_asin:
    if comp['status']==0:ref=run([temp/'oracle'],temp)
    ok=q==dict(status=0,stdout='',stderr='') and r['status']==0 and not r['stderr'] and ref is not None and ref['status']==0 and not ref['stderr'] and r['stdout']==ref['stdout']
    outcome='complete_original_execution_exact_bytes'
   else:
    ok=q['status']==1 and not q['stdout'] and r['status']==1 and not r['stdout'] and 'Unsupported procedure or array reference: asin' in r['stderr']
    outcome='unchanged_original_requires_companion_asin_feature'
   ok=ok and comp['status']==0 and 'Backtrace' not in r['stderr'] and 'Fortran runtime error' not in r['stderr']
   rows.append(dict(name=c['name'],passed=bool(ok),outcome=outcome,check=q,run=r,gnu_flags=flags,compile=comp,reference=ref))
   print(('PASS: ' if ok else 'FAIL: ')+c['name']+' '+outcome)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),combined_asin=a.combined_asin,total=len(rows),failed=sum(not r['passed'] for r in rows),complete_original_passes=sum(r['passed'] and r['outcome']=='complete_original_execution_exact_bytes' for r in rows),cases=rows)
 a.result.write_text(json.dumps(result,indent=2)+'\n');return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
