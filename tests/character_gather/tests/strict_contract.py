"""Strict observed-result contracts; no catch-all rejection acceptance."""
import re
NUMERIC_RECORDS={'empty','zero_length','len_undefined_metadata','released_constructor_cache','fixed_unallocated_len','deferred_empty_len'}
def compare_stdout(name,actual,expected):
 if name not in NUMERIC_RECORDS:return actual==expected
 a=actual.splitlines();b=expected.splitlines()
 if len(a)!=len(b):return False
 for x,y in zip(a,b):
  xx=x.split();yy=y.split()
  if not xx or any(re.fullmatch(r'[+-]?\d+',t) is None for t in xx+yy):return False
  if [int(t)for t in xx]!=[int(t)for t in yy]:return False
 return True
def diagnostic(actual,source,status,line,column,message):
 return actual['status']==status and actual['stdout']=='' and actual['stderr']==f'{source}:{line}:{column}: {message}\n'
def check_record(row,expectation,source):
 errors=[];check=row['check'];run=row.get('candidate_run')
 if expectation['phase']=='success':
  if check!={'status':0,'stdout':'','stderr':''}:errors.append('check differs')
  if not run or run['status']!=0 or run['stderr']!='' or not compare_stdout(row['name'],run['stdout'],expectation['stdout']):errors.append('run differs')
 elif expectation['phase']=='check':
  if not diagnostic(check,source,**expectation['diagnostic']):errors.append('check diagnostic differs')
  if run is not None:errors.append('unexpected execution')
 elif expectation['phase']=='runtime':
  if check!={'status':0,'stdout':'','stderr':''}:errors.append('check differs')
  if run is None or not diagnostic(run,source,**expectation['diagnostic']):errors.append('runtime diagnostic differs')
 else:errors.append('unrecognized expected phase')
 return errors
