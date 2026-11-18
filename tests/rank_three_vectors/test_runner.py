from pathlib import Path
import tempfile,subprocess,shutil,json
from run_tests import candidate_errors,gnu_errors,check_provenance
R=Path(__file__).resolve().parent
checks=0
def require(ok):
 global checks
 checks+=1
 assert ok,checks
source=Path('/source path/example.f90');silent=dict(code=0,out='',err='')
for stage in ['success','compile','runtime']:
 c=dict(stage=stage,expected='1\n' if stage=='success' else '',diagnostic=None if stage=='success' else '4:5: invalid gather')
 diag='' if stage=='success' else str(source)+':4:5: invalid gather\n'
 check=silent.copy() if stage!='compile' else dict(code=1,out='',err=diag)
 ran=dict(code={'success':0,'compile':1,'runtime':2}[stage],out=c['expected'],err=diag)
 require(not candidate_errors(c,source,check,ran))
 for item in ['check','run']:
  old=check if item=='check' else ran
  for key,values in [('code',[None,-11,3,2 if old['code']==0 else 0]),('out',[old['out']+' ',old['out']+'\n']),('err',[old['err']+' ',old['err']+'\n'])]:
   for value in values:
    bad=old.copy();bad[key]=value;require(bool(candidate_errors(c,source,bad if item=='check' else check,bad if item=='run' else ran)))
 if stage!='success':
  for diag in [None,'','0:5: invalid gather','4:5: invalid gather\nextra']:
   bad=c.copy();bad['diagnostic']=diag;require(bool(candidate_errors(bad,source,check,ran)))
  for old,new in [('4:5','4:6'),('4:5','5:5'),('example.f90','other.f90'),('invalid gather','unrelated'),('\n','')]:
   bad=ran.copy();bad['err']=bad['err'].replace(old,new);require(bool(candidate_errors(c,source,check,bad)))
# GNU is an independent oracle, never a permissive fallback for any failure.
compiled=dict(code=0,out='',err='')
for mode in ['run','compile','reject']:
 c=dict(gnu=mode,expected='1\n')
 comp=compiled.copy();ran=dict(code=0,out='1\n',err='') if mode=='run' else None
 if mode=='reject':comp=dict(code=1,out='',err='Non-variable expression in variable definition context')
 require(not gnu_errors(c,comp,ran))
 for field,values in [('code',[None,-11,3,0 if mode=='reject' else 1]),('out',['unexpected']),('err',['Backtrace','Fortran runtime error','TIMEOUT'])]:
  for value in values:
   bad=comp.copy();bad[field]=value;require(bool(gnu_errors(c,bad,ran)))
 if mode=='run':
  for field,values in [('code',[None,-11,1,2]),('out',['1','01\n','1 \n','1\n\n','0\n']),('err',[' ','\n','Backtrace'])]:
   for value in values:
    bad=ran.copy();bad[field]=value;require(bool(gnu_errors(c,comp,bad)))
 else:
  require(bool(gnu_errors(c,comp,dict(code=0,out='',err=''))))
require(bool(gnu_errors(dict(gnu='compile',expected=''),dict(code=0,out='',err=' '),None)))
require(bool(gnu_errors(dict(gnu='reject',expected=''),dict(code=1,out='',err='unrelated compile failure'),None)))
# Valid GNU code can retain an independently specified candidate subset boundary.
c=dict(gnu='run',expected='',gnu_expected='1\n')
require(not gnu_errors(c,dict(code=0,out='',err=''),dict(code=0,out='1\n',err='')))
require(bool(gnu_errors(c,dict(code=0,out='',err=''),dict(code=0,out='',err=''))))
require(check_provenance())
with tempfile.TemporaryDirectory(prefix='tensor-replay-') as tmp:
 d=Path(tmp);(d/'cases').mkdir();(d/'source').mkdir();shutil.copy2(R/'generate_cases.py',d/'generate_cases.py');shutil.copy2(R/'source/exact_closure.f90',d/'source/exact_closure.f90')
 p=subprocess.run(['python3',d/'generate_cases.py'],capture_output=True);require(p.returncode==0)
 require((R/'manifest.json').read_bytes()==(d/'manifest.json').read_bytes())
 for p in (R/'cases').glob('*.f90'):require(p.read_bytes()==(d/'cases'/p.name).read_bytes())
print(checks,'harness/provenance/replay checks pass')
