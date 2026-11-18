import unittest
from oracle_contracts import oracle_check
class OracleContracts(unittest.TestCase):
 def test_rejection(self):
  c=dict(name='duplicate',gnu_mode='reject');p=dict(code=1,stdout='',stderr='s.f90:4: Error: already declared\n')
  self.assertFalse(oracle_check(c,'s.f90',p,None))
  for field,value in [('code',0),('code',-11),('stdout','junk'),('stderr','s.f90: unrelated'),('stderr','other: already declared'),('stderr','s.f90: already declared\nBacktrace')]:
   q={**p,field:value};self.assertTrue(oracle_check(c,'s.f90',q,None))
  self.assertTrue(oracle_check(c,'s.f90',p,dict(code=0,stdout='',stderr='')))
 def test_compile_only(self):
  c=dict(name='undefined_first',gnu_mode='compile_only');p=dict(code=0,stdout='',stderr='')
  self.assertFalse(oracle_check(c,'s',p,None))
  self.assertTrue(oracle_check(c,'s',p,p))
  for q in [dict(code=None,stdout='',stderr='TIMEOUT'),dict(code=0,stdout='',stderr='warning'),dict(code=1,stdout='',stderr='error')]:self.assertTrue(oracle_check(c,'s',q,None))
 def test_execute(self):
  c=dict(name='both_default',gnu_mode='execute',category='success',expected='7 8\n');p=dict(code=0,stdout='',stderr='');q=dict(code=0,stdout='7 8\n',stderr='')
  self.assertFalse(oracle_check(c,'s',p,q))
  for field,value in [('code',1),('code',-11),('stdout','7 9\n'),('stdout','7 8'),('stderr','TIMEOUT'),('stderr','Fortran runtime error')]:self.assertTrue(oracle_check(c,'s',p,{**q,field:value}))
  self.assertTrue(oracle_check(c,'s',p,None))
 def test_numeric(self):
  c=dict(name='exact_user',gnu_mode='execute',category='numeric',expected='1000');p=dict(code=0,stdout='',stderr='')
  self.assertFalse(oracle_check(c,'s',p,dict(code=0,stdout=' 1000.0000\n',stderr='')))
  for out in ['NaN\n','Infinity\n','1000\nextra\n','1001\n']:self.assertTrue(oracle_check(c,'s',p,dict(code=0,stdout=out,stderr='')))
if __name__=='__main__':unittest.main()
