#!/usr/bin/env python3
import unittest
import run_tests as r

class Contracts(unittest.TestCase):
 def test_exact_character_records(self):
  for bad in ['PASS',' PASS\n','PASS \n','PASS\n\n','PASS\r\n']:
   with self.subTest(bad=bad):self.assertFalse(r.compare(bad,'PASS\n'))
  self.assertTrue(r.compare('PASS\n','PASS\n'))
 def test_empty_is_zero_bytes(self):
  for bad in [' ','\t','\n','\r\n']:
   with self.subTest(bad=bad):self.assertFalse(r.compare(bad,''))
  self.assertTrue(r.compare('',''))
 def test_pending_record_exact(self):
  self.assertTrue(r.compare('KEEP','KEEP'))
  for bad in ['KEEP\n','KEEPBAD',' KEEP']:
   with self.subTest(bad=bad):self.assertFalse(r.compare(bad,'KEEP'))
 def test_success_stderr_and_check_output(self):
  case=dict(category='success',expected_stdout='PASS\n')
  good=dict(code=0,out='PASS\n',err='');check=dict(code=0,out='',err='')
  self.assertEqual(r.candidate_errors(case,check,good),[])
  for field,value in [('err',' '),('out','\n'),('code',1)]:
   with self.subTest(field=field):self.assertTrue(r.candidate_errors(case,dict(check,**{field:value}),good))
  self.assertTrue(r.candidate_errors(case,check,dict(good,err=' ')))
 def test_runtime_stage(self):
  case=dict(category='runtime',expected_stdout='',diagnostic='unsupported WRITE unit')
  check=dict(code=0,out='',err='');run=dict(code=2,out='',err='unsupported WRITE unit')
  self.assertEqual(r.candidate_errors(case,check,run),[])
  for bad in [dict(run,code=1),dict(run,out=' '),dict(run,err=''),dict(run,err='some other failure')]:
   with self.subTest(bad=bad):self.assertTrue(r.candidate_errors(case,check,bad))
 def test_list_tokens_preserve_records(self):
  self.assertTrue(r.compare('        17 T ok\n',' 17 T ok\n',mode='tokens'))
  for bad in ['17 T ok\n\n','17 T other\n','17 T ok extra\n','17 T ok','17 T ok\r\n']:
   with self.subTest(bad=bad):self.assertFalse(r.compare(bad,' 17 T ok\n',mode='tokens'))
 def test_diagnostic_path_spoof(self):
  c=dict(category='runtime',expected_stdout='',diagnostic='unsupported WRITE unit')
  self.assertTrue(r.candidate_errors(c,dict(code=0,out='',err=''),dict(code=2,out='',err='/tmp/unsupported WRITE unit.f90:3:7: unrelated failure\n')))
 def test_host_crash_not_source_rejection(self):
  c=dict(category='reject',expected_stdout='')
  crash=dict(code=1,out='',err='internal compiler error: backtrace')
  self.assertTrue(r.candidate_errors(c,crash,crash))
  self.assertTrue(r.gnu_compile_errors(dict(baseline='reject'),crash))
 def test_gnu_noise(self):
  c=dict(expected_stdout='PASS\n')
  self.assertTrue(r.gnu_success_errors(c,dict(code=0,out='PASS\n',err=' ')))
  self.assertEqual(r.gnu_success_errors(c,dict(code=0,out='PASS\n',err='')),[])

if __name__=='__main__':unittest.main()
