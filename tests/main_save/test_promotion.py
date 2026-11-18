import unittest
from run_tests import compare,case_compare,candidate_errors
class PromotionChecks(unittest.TestCase):
 def test_exact_records(self):
  for wrong in ['1.0 2\n','1 2','1 2\n\n','1\n2\n','nan 2\n','1 2 3\n','1 3\n','9007199254740992\n']:
   self.assertFalse(compare(wrong,'1 2\n' if '9007' not in wrong else '9007199254740993\n',mode='integer_records'))
  self.assertTrue(compare('  +1 2\n','1 2\n',mode='integer_records'))
 def test_exact_formatted_middle(self):
  case=dict(expected_stdout=' 1 2\n-3 47\n',compare_mode='integer_records',exact_records=[1])
  self.assertTrue(case_compare('1 2\n-3 47\n',case))
  self.assertFalse(case_compare('1 2\n -3 47\n',case))
 def test_silent_stages(self):
  case=dict(category='success',expected_stdout='1\n',compare_mode='integer_records',strict_process=True)
  good=dict(code=0,out='1\n',err='');check=dict(code=0,out='',err='')
  self.assertFalse(candidate_errors(case,check,good))
  self.assertTrue(candidate_errors(case,dict(check,out=' '),good))
  self.assertTrue(candidate_errors(case,dict(check,err='\n'),good))
  self.assertTrue(candidate_errors(case,check,dict(good,err=' ')))
if __name__=='__main__':unittest.main()
