import re
from decimal import Decimal, InvalidOperation
DIAGNOSTICS={
'undefined_last':(11,10,'read of uninitialized derived component'),
'undefined_first':(11,10,'read of uninitialized derived component'),
'undefined_middle':(11,10,'read of uninitialized derived component'),
'no_double_colon':(4,11,'Component initialization requires ::'),
'duplicate':(4,17,'Duplicate component name'),
'wrong_type':(4,24,'Incompatible assignment types'),
'nonconstant':(5,19,'Component defaults require supported scalar constant expressions'),
'trailing_comma':(4,20,'Expected a nonreserved name'),
'intent_out_undefined':(17,10,'read of uninitialized derived component'),
'missing_required_first':(11,7,'Omitted structure component requires a default initializer')}
CRASH=re.compile(r'TIMEOUT|backtrace|traceback|segmentation|runtime error|SIGSEGV|SIGABRT|internal compiler error',re.I)
def check(case,source,results):
 errors=[];cat=case['category']
 for stage in ('check','run'):
  r=results[stage];negative=cat=='reject' or (cat=='runtime' and stage=='run')
  if CRASH.search(r['stdout']+r['stderr']):errors.append(stage+' crash')
  if negative:
   line,col,msg=DIAGNOSTICS[case['name']]
   if r!=dict(code=1 if cat=='reject' else 2,stdout='',stderr=f'{source}:{line}:{col}: {msg}\n'):errors.append(stage+' exact diagnostic')
  elif stage=='check':
   if r!=dict(code=0,stdout='',stderr=''):errors.append('silent check')
  else:
   if r['code']!=0 or r['stderr']:errors.append('successful run status')
   if cat=='numeric':
    try:
     value=Decimal(r['stdout'].strip());ok=value.is_finite() and value==Decimal(case['expected']) and r['stdout'].endswith('\n') and len(r['stdout'].splitlines())==1
    except InvalidOperation:ok=False
   else:ok=r['stdout']==case['expected']
   if not ok:errors.append('output')
 return errors
