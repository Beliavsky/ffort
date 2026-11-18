#!/usr/bin/env python3
"""Bounded large list-directed records; retain only hashes, not huge log payloads."""
import argparse,hashlib,json,math,subprocess,tempfile,time
from pathlib import Path
ROOT=Path(__file__).resolve().parent
LIMIT=16*1024*1024

def call(args,cwd=None):
 start=time.monotonic()
 p=subprocess.run([str(x) for x in args],cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=30)
 return {'code':p.returncode,'out':p.stdout,'err':p.stderr,'seconds':time.monotonic()-start}

def evidence(result):
 return {'code':result['code'],'stdout_bytes':len(result['out']),
         'stdout_sha256':hashlib.sha256(result['out']).hexdigest(),
         'stderr':result['err'].decode(errors='replace'),'seconds':result['seconds']}

def output_ok(data,kind,count=0):
 if kind=='numeric':
  words=data.split()
  if len(words)!=count:return False
  try:return all(math.isfinite(float(x)) and float(x)==0.125 for x in words)
  except ValueError:return False
 if kind=='exact':return data==b' '+b'x'*(LIMIT-1)+b'\n'
 if kind=='over':return data==b''
 if kind=='over_prior':return data==b'before\n'
 raise ValueError('unknown staging test')

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',type=Path,default=ROOT/'staging-results.json');a=ap.parse_args();a.candidate=a.candidate.resolve()
 results=[]
 with tempfile.TemporaryDirectory(prefix='stdout-staging-') as folder:
  folder=Path(folder)
  for form in ['print','write']:
   cases=[(f'staging_real8_{n}_{form}','numeric',n) for n in [4096,65536]]
   cases += [(f'staging_character_{label}_{form}',label,0) for label in ['exact','over','over_prior']]
   for name,kind,count in cases:
    source=ROOT/(name+'.f90');check=call([a.candidate,'--check',source]);actual=call([a.candidate,source]);negative=kind.startswith('over')
    ok=check['code']==0 and not check['out'] and not check['err']
    ok=ok and actual['code']==(2 if negative else 0) and output_ok(actual['out'],kind,count)
    if negative:ok=ok and b'list-directed output exceeds 16777216 characters' in actual['err']
    else:ok=ok and not actual['err']
    compile=call([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all',source,'-o',folder/'oracle'],folder)
    ok=ok and compile['code']==0;oracle=None
    if not negative and compile['code']==0:
     oracle=call([folder/'oracle'],folder);ok=ok and oracle['code']==0 and not oracle['err'] and output_ok(oracle['out'],kind,count)
    results.append({'name':name,'pass':bool(ok),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'check':evidence(check),'actual':evidence(actual),'gnu_compile':evidence(compile),'gnu_run':evidence(oracle) if oracle else None})
    print(('PASS ' if ok else 'FAIL ')+name,flush=True)
 report={'total':len(results),'failed':sum(not c['pass'] for c in results),'gnu_executed':sum(c['gnu_run'] is not None for c in results),'gnu_compile_only':sum(c['gnu_run'] is None for c in results),'candidate_sha256':hashlib.sha256(a.candidate.read_bytes()).hexdigest(),'cases':results}
 a.result.write_text(json.dumps(report,indent=2)+'\n');return report['failed']!=0
if __name__=='__main__':raise SystemExit(main())
