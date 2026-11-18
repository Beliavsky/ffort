import unittest
from run_tests import output_matches,successful_check,known_o0_observation
class FormatByteTests(unittest.TestCase):
 def test_exact_bytes(self):
  self.assertTrue(output_matches('a b \n','a b \n',{}))
  for changed in ['ab \n','a  b \n','a b\n','A b \n','a b ','a b \n\n']:
   self.assertFalse(output_matches(changed,'a b \n',{}))
 def test_numeric_spelling_exact(self):
  for a,b in [('0.0','-0.0'),('1e-400','0.0'),('1D0','1E0'),('1','1.0')]:
   self.assertFalse(output_matches(a,b,{}))
 def test_expected_bytes(self):
  self.assertFalse(output_matches('wrong','wrong',{'stdout':'right'}))
 def test_silent_check(self):
  self.assertTrue(successful_check(dict(status=0,stdout='',stderr='')))
  for stream in ['stdout','stderr']:
   self.assertFalse(successful_check(dict(status=0,stdout=' ' if stream=='stdout' else '',stderr=' ' if stream=='stderr' else '')))
  for status in [1,2,-9]:
   self.assertFalse(successful_check(dict(status=status,stdout='',stderr='')))
class OracleScopeTests(unittest.TestCase):
 def test_annotated_o0_is_not_candidate_tolerance(self):
  c={'stdout':'c_1 |\nb_2 |\na_3 |\n','gnu_o0_discrepancy':'c_1 |\n_2  |\n_3  |\n'}
  self.assertTrue(known_o0_observation(dict(status=0,stdout=c['gnu_o0_discrepancy'],stderr=''),c))
  self.assertTrue(known_o0_observation(dict(status=0,stdout=c['stdout'],stderr=''),c))
  self.assertFalse(output_matches(c['gnu_o0_discrepancy'],c['stdout'],c))
  for value in ['wrong',c['stdout']+' ',c['gnu_o0_discrepancy'].replace('_2','_9')]:
   self.assertFalse(known_o0_observation(dict(status=0,stdout=value,stderr=''),c))
  self.assertFalse(known_o0_observation(dict(status=0,stdout=c['stdout'],stderr='warning'),c))
  self.assertFalse(known_o0_observation(dict(status=2,stdout=c['stdout'],stderr=''),c))
if __name__=='__main__':unittest.main()

