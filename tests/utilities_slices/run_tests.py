#!/usr/bin/env python3
"""Differential checks for exact utility extracts and supported real-kind inquiries."""
import argparse,hashlib,json,math,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def run(cmd,cwd=None):
 r=subprocess.run([str(x) for x in cmd],cwd=cwd,text=True,capture_output=True,timeout=30)
 return {'status':r.returncode,'stdout':r.stdout,'stderr':r.stderr}

def tokens(text):
 return text.lower().replace('d','e').split()

def equal(a,b):
 a=tokens(a);b=tokens(b)
 if len(a)!=len(b):return False
 for x,y in zip(a,b):
  try:
   if not math.isclose(float(x),float(y),rel_tol=1e-10,abs_tol=1e-12):return False
  except ValueError:
   if x!=y:return False
 return True

def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True,type=Path);p.add_argument('--gfortran',default='gfortran');p.add_argument('--result',default='results.json');a=p.parse_args();a.candidate=a.candidate.resolve()
 cases=json.loads((ROOT/'manifest.json').read_text())['cases'];results=[]
 with tempfile.TemporaryDirectory(prefix='utility-slices-') as tmp:
  tmp=Path(tmp)
  for c in cases:
   src=ROOT/(c['name']+'.f90');exe=tmp/'oracle';g=run([a.gfortran,'-std=f2018','-fcheck=all',src,'-o',exe],tmp)
   check=run([a.candidate,'--check',src]);r=run([a.candidate,src]);oracle=None
   if g['status']==0:oracle=run([exe])
   if c['expected']=='reject':
    fragment=c['diagnostic_contains']
    ok=check['status']==1 and r['status']==1 and not r['stdout'] and not check['stdout'] and fragment in check['stderr'] and fragment in r['stderr']
    ok=ok and ((g['status']!=0) if c.get('gnu_invalid') else (g['status']==0))
   else:
    want=' '.join(str(x) for x in c['literal_expected']) if c.get('literal_expected') is not None else (oracle or {}).get('stdout','')
    ok=g['status']==0 and oracle['status']==0 and check['status']==0 and not check['stdout'] and not check['stderr'] and r['status']==0 and not r['stderr'] and equal(r['stdout'],want)
   results.append({'name':c['name'],'pass':ok,'expected':c['expected'],'gfortran':g,'oracle':oracle,'check':check,'candidate':r,'literal_expected':c.get('literal_expected')})
   print(('PASS' if ok else 'FAIL')+': '+c['name'],flush=True)
 result={'candidate_sha256':hashlib.sha256(a.candidate.read_bytes()).hexdigest(),'candidate_version':run([a.candidate,'--version'])['stdout'].strip(),'gfortran_version':run([a.gfortran,'--version'])['stdout'].splitlines()[0],'total':len(results),'failed':sum(not r['pass'] for r in results),'cases':results};out=Path(a.result);out=out if out.is_absolute() else ROOT/out;out.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return bool(result['failed'])
if __name__=='__main__':raise SystemExit(main())
