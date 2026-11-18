"""Adversarial candidate/GNU stage, exact byte and timing-oracle policy checks."""
from copy import deepcopy
from run_tests import candidate_errors,gnu_errors,compare
from check_original_utility import valid_output
checks=0
def require(ok):
 global checks
 checks+=1
 assert ok,checks
source='/source with spaces/case.f90'
blank={'code':0,'out':'','err':''}
for stage in ('success','runtime','compile'):
 case={'stage':stage,'diagnostic':None if stage=='success' else '4:2: bounded slash failure','expected':'KEEP' if stage=='runtime' else 'X \n' if stage=='success' else '', 'integer_records':[],'gnu':'run'}
 check=blank.copy() if stage!='compile' else {'code':1,'out':'','err':source+':4:2: bounded slash failure\n'}
 execution={'code':{'success':0,'runtime':2,'compile':1}[stage],'out':case['expected'],'err':'' if stage=='success' else source+':4:2: bounded slash failure\n'}
 require(not candidate_errors(case,check,execution,source))
 for part in ('check','run'):
  old=check if part=='check' else execution
  for key,vals in [('code',[-11,None,3,0 if old['code'] else 2]),('out',[old['out']+' ',old['out']+'\n',old['out']+'X']),('err',[old['err']+' ',old['err']+'\n',old['err']+'warning\n'])]:
   for value in vals:
    new=old.copy();new[key]=value
    require(bool(candidate_errors(case,new if part=='check' else check,new if part=='run' else execution,source)))
 if stage!='success':
  for err in ['',execution['err'].replace('4:2:','4:3:'),execution['err'].replace('4:2:','5:2:'),execution['err'].replace('case.f90','other.f90'),execution['err'].replace('bounded slash failure','other error'),execution['err'].rstrip('\n'),execution['err']+'extra error\n']:
   new=execution.copy();new['err']=err;require(bool(candidate_errors(case,check,new,source)))
  for diagnostic in (None,'','4:2','0:2: failure','4:2: failure\nextra'):
   bad=case.copy();bad['diagnostic']=diagnostic;require(bool(candidate_errors(bad,check,execution,source)))
case={'stage':'success','gnu':'run','expected':'X \n','integer_records':[]}
q={'code':0,'out':'X \n','err':''}
require(not gnu_errors(case,blank,q))
for key,values in [('code',[1,None,-11]),('out',['X\n','X \n\n','X \r\n']),('err',[' ','\n','warning'])]:
 for value in values:
  new=q.copy();new[key]=value;require(bool(gnu_errors(case,blank,new)))
for key,value in [('code',1),('out',' '),('err','\n')]:
 new=blank.copy();new[key]=value;require(bool(gnu_errors(case,new,q)))
require(bool(gnu_errors(case,blank,None)))
require(not gnu_errors(dict(case,gnu='compile'),blank))
require(not compare('X\r\n','X\n'))
require(not compare('X\n','X \n'))
for out in [b'\n wall time elapsed(s) =     0.000\n',b'\n wall time elapsed(s) =    12.345\n']:
 require(valid_output(out))
 for mutant in [out[1:],out+b'\n',out.replace(b'elapsed',b'elapSed'),out.replace(b'\n',b'\r\n'),out.replace(b' = ',b'='),out[:-1]]:
  require(not valid_output(mutant))
for field in [b'   -0.001',b'      NaN',b' Infinity',b' 1.00E+00',b'  123.45 ',b' 123.4567',b'*********']:
 require(not valid_output(b'\n wall time elapsed(s) = '+field+b'\n'))
print(checks,'policy checks pass')
