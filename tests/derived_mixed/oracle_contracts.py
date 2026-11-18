from contracts import CRASH, check
REJECTIONS={
'no_double_colon':'Syntax error in data declaration',
'duplicate':'already declared',
'wrong_type':'Cannot convert LOGICAL(4) to INTEGER(4)',
'nonconstant':'does not reduce to a constant expression',
'trailing_comma':'Invalid character in name',
'missing_required_first':'No initializer for component'}
def oracle_check(case,source,compiled,ran):
 errors=[];mode=case['gnu_mode']
 if mode not in ('execute','compile_only','reject'):return ['unknown oracle mode']
 if CRASH.search(compiled['stdout']+compiled['stderr']):errors.append('compiler crash/timeout')
 if mode=='reject':
  if compiled['code']!=1 or compiled['stdout'] or REJECTIONS[case['name']] not in compiled['stderr'] or str(source)+':' not in compiled['stderr']:errors.append('wrong compiler rejection')
  if ran is not None:errors.append('rejected source executed')
  return errors
 if compiled!=dict(code=0,stdout='',stderr=''):errors.append('compiler success not silent')
 if mode=='compile_only':
  if ran is not None:errors.append('undefined-value source executed')
 elif ran is None:errors.append('execution missing')
 else:errors.extend(check(case,source,dict(check=dict(code=0,stdout='',stderr=''),run=ran)))
 return errors
