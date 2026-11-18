#!/usr/bin/env python3
"""Self-tests reject false passes, precision loss and unsafe process outcomes."""
import json,sys,unittest
from pathlib import Path
from run_tests import compare,candidate_errors,execute
ROOT=Path(__file__).resolve().parent
def r(code=0,out='',err=''):return dict(code=code,out=out,err=err)
class RunnerTests(unittest.TestCase):
 def test_exact_large_integers(self):
  self.assertTrue(compare(' 9007199254740993\n','9007199254740993'))
  self.assertFalse(compare('9007199254740992','9007199254740993'))
  self.assertFalse(compare('9007199254740993.0','9007199254740993'))
 def test_valid_success(self):self.assertFalse(candidate_errors(dict(category='success',expected_stdout='1'),r(),r(out='1')))
 def test_success_no_stderr(self):self.assertTrue(candidate_errors(dict(category='success',expected_stdout='1'),r(),r(out='1',err='warning')))
 def test_runtime_exact_status(self):
  c=dict(category='runtime',expected_stdout='',diagnostic='overflow')
  self.assertFalse(candidate_errors(c,r(),r(2,err='integer overflow')))
  for code in [0,1,3,-11,None]:self.assertTrue(candidate_errors(c,r(),r(code,err='overflow')))
 def test_static_exact_status(self):
  c=dict(category='invalid',expected_stdout='')
  self.assertFalse(candidate_errors(c,r(1,err='bad kind'),r(1,err='bad kind')))
  self.assertTrue(candidate_errors(c,r(2,err='bad kind'),r(1,err='bad kind')))
 def test_check_no_output(self):self.assertTrue(candidate_errors(dict(category='success',expected_stdout='1'),r(out='leak'),r(out='1')))
 def test_rejection_no_output(self):self.assertTrue(candidate_errors(dict(category='runtime',expected_stdout=''),r(),r(2,out='leak',err='overflow')))
 def test_rejection_requires_diagnostic(self):self.assertTrue(candidate_errors(dict(category='runtime',expected_stdout=''),r(),r(2)))
 def test_path_does_not_satisfy_diagnostic(self):self.assertTrue(candidate_errors(dict(category='runtime',expected_stdout='',diagnostic='overflow'),r(),r(2,err='/tmp/overflow.f90:3:1: different error')))
 def test_timeout(self):self.assertIsNone(execute([sys.executable,'-c','import time;time.sleep(2)'],timeout=.02)['code'])
 def test_missing_executable(self):self.assertIsNone(execute([str(ROOT/'no-such-executable')])['code'])
 def test_manifest_sources_and_policies(self):
  cases=json.loads((ROOT/'manifest.json').read_text())['cases'];self.assertEqual(len(cases),23)
  for c in cases:
   self.assertTrue((ROOT/c['source']).is_file());self.assertIn(c['category'],['success','runtime','invalid']);self.assertIn(c['baseline'],['run','compile','skip'])
   if c['baseline']=='skip':self.assertTrue(c['baseline_note'])
if __name__=='__main__':unittest.main()
