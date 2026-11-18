import unittest
from run_accuracy import assess,ulp,known_gnu_difference

def row(reference='1',function='bessel_j0',oscillatory=False,near_root=False,envelope='1',index=1):
 return dict(index=index,kind=8,function=function,n=0,x_hex='0x1.0p+0',reference=reference,near_root=near_root,oscillatory=oscillatory,envelope=envelope)

class AccuracyTests(unittest.TestCase):
 def test_exact_result(self):self.assertTrue(assess('1 1.0',[row()],8)[0]['passed'])
 def test_nonfinite(self):
  for val in ['NaN','Infinity','-Infinity']:
   self.assertFalse(assess('1 '+val,[row()],8)[0]['passed'])
 def test_poisoned_huge(self):self.assertFalse(assess('1 1e999',[row()],8)[0]['passed'])
 def test_normal_may_not_collapse_to_zero(self):
  self.assertFalse(assess('1 0',[row('1e-300')],8)[0]['passed'])
  self.assertFalse(assess('1 0',[row('1e-30',oscillatory=True)],4)[0]['passed'])
 def test_rounding_underflow_is_permitted(self):self.assertTrue(assess('1 0',[row('1e-2000')],8)[0]['passed'])
 def test_relative_budget_away_from_oscillation(self):
  self.assertFalse(assess('1 1.0001',[row()],8)[0]['passed'])
  self.assertFalse(assess('1 1.00001e-100',[row('1e-100')],8)[0]['passed'])
 def test_oscillatory_absolute_budget(self):
  self.assertTrue(assess('1 1.1e-16',[row('1e-16',oscillatory=True,near_root=True)],8)[0]['passed'])
  self.assertFalse(assess('1 1e-10',[row('1e-16',oscillatory=True,near_root=True)],8)[0]['passed'])
 def test_erf_ulp_budget(self):
  self.assertTrue(assess('1 1.0',[row('1',function='erf')],8)[0]['passed'])
  self.assertFalse(assess('1 1.00001',[row('1',function='erf')],8)[0]['passed'])
 def test_output_count(self):
  with self.assertRaises(AssertionError):assess('',[row()],8)
  with self.assertRaises(AssertionError):assess('1 1\n2 1',[row()],8)
 def test_order_and_tokens(self):
  with self.assertRaises(AssertionError):assess('2 1',[row()],8)
  with self.assertRaises(AssertionError):assess('1 1 extra',[row()],8)
 def test_subnormal_ulp(self):
  self.assertEqual(ulp(0,4),float.fromhex('0x1p-149'))
  self.assertEqual(ulp(0,8),float.fromhex('0x1p-1074'))
class KnownGNUPrecisionTests(unittest.TestCase):
 def sample(self):
  return ({'function':'bessel_jn','kind':4},{'n':16,'x_hex':'0x1.0000000000000p+3'},
          {'passed':False,'result':'0.000078006436524447054','budget_fraction':1.1037948900614079})
 def test_exact_record_only(self):
  s,r,v=self.sample();self.assertTrue(known_gnu_difference(s,r,v))
  s['kind']=8;self.assertFalse(known_gnu_difference(s,r,v))
 def test_nonfinite_or_wrong_value_not_exempt(self):
  for value in ['NaN','Infinity','0','0.0000780064']:
   s,r,v=self.sample();v['result']=value;self.assertFalse(known_gnu_difference(s,r,v))
 def test_wrong_error_or_identity_not_exempt(self):
  s,r,v=self.sample();v['budget_fraction']=None;self.assertFalse(known_gnu_difference(s,r,v))
  s,r,v=self.sample();v['budget_fraction']=10;self.assertFalse(known_gnu_difference(s,r,v))
  s,r,v=self.sample();r['n']=32;self.assertFalse(known_gnu_difference(s,r,v))
  s,r,v=self.sample();v['passed']=True;self.assertFalse(known_gnu_difference(s,r,v))

if __name__=='__main__':unittest.main()
