import unittest
from copy import deepcopy
from contracts import check,DIAGNOSTICS
class Contracts(unittest.TestCase):
 def test_mutations(self):
  for name,(line,col,msg) in DIAGNOSTICS.items():
   runtime=name.startswith('undefined') or name=='intent_out_undefined'
   c=dict(name=name,category='runtime' if runtime else 'reject');source='/tmp/source.f90';err=f'{source}:{line}:{col}: {msg}\n'
   baseline=dict(check=dict(code=0,stdout='',stderr='') if runtime else dict(code=1,stdout='',stderr=err),run=dict(code=2 if runtime else 1,stdout='',stderr=err))
   self.assertEqual(check(c,source,baseline),[])
   for field,value in [('code',0),('code',-11),('stdout','junk\n'),('stderr',err.replace(msg,'unrelated error')),('stderr',err.replace(f':{line}:',':999:')),('stderr',err.replace(source,'wrong.f90')),('stderr',err+'Backtrace\n'),('stderr',err.rstrip()),('stderr',err+'\n')]:
    r=deepcopy(baseline);r['run'][field]=value;self.assertTrue(check(c,source,r),(name,field,value))
 def test_success(self):
  c=dict(name='success',category='success',expected='7 8\n');r=dict(check=dict(code=0,stdout='',stderr=''),run=dict(code=0,stdout='7 8\n',stderr=''))
  self.assertFalse(check(c,'x',r))
  for value in ('7 9\n','7 8','7 8\nextra\n'):
   q=deepcopy(r);q['run']['stdout']=value;self.assertTrue(check(c,'x',q))
 def test_numeric(self):
  c=dict(name='exact_user',category='numeric',expected='1000');r=dict(check=dict(code=0,stdout='',stderr=''),run=dict(code=0,stdout=' 1000.000\n',stderr=''))
  self.assertFalse(check(c,'x',r))
  for value in ('NaN\n','Infinity\n','999\n','1000\n\n','1000'):
   q=deepcopy(r);q['run']['stdout']=value;self.assertTrue(check(c,'x',q))
if __name__=='__main__':unittest.main()
