import unittest
from run_tests import output_matches,successful_check
from check_provenance import check
class RuntimeFormatHarness(unittest.TestCase):
 def test_exact_records(self):
  for value in ['A  B\n','A','A  ','\n','']:
   self.assertTrue(output_matches(value,value,{}))
   self.assertFalse(output_matches(value+'\n',value,{}))
 def test_spaces_and_case(self):
  for a,b in [('AB','A B'),('A ','A'),('A','a'),('d','e'),('a\nb','ab')]:self.assertFalse(output_matches(a,b,{}))
 def test_numbers_are_bytes(self):
  for a,b in [('0.0','-0.0'),('1','1.0'),('1D0','1E0'),('0','1e-400'),('NaN','nan')]:self.assertFalse(output_matches(a,b,{}))
 def test_independent_expected(self):
  self.assertFalse(output_matches('wrong','wrong',dict(stdout='right')))
 def test_silent_check(self):
  self.assertTrue(successful_check(dict(status=0,stdout='',stderr='')))
  for s in ['stdout','stderr']:
   d=dict(status=0,stdout='',stderr='');d[s]=' ';self.assertFalse(successful_check(d))
  for n in [1,2,-9]:self.assertFalse(successful_check(dict(status=n,stdout='',stderr='')))
 def test_original_provenance(self):check()
if __name__=='__main__':unittest.main()
