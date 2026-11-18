#!/usr/bin/env python3
import copy,unittest
from run_tests import errors,diagnostic,gnu_errors
SOURCE='/portable root/cases/reject.f90'
class Harness(unittest.TestCase):
 def setUp(self):
  self.case=dict(category='reject',diagnostic=dict(phase='source',status=1,line=18,column=31,message='Unknown keyword or excess actual argument: n'))
  self.rejection=dict(status=1,stdout='',stderr=diagnostic(self.case,SOURCE))
  self.clean=dict(status=0,stdout='',stderr='')
 def test_success_exact(self):
  c=dict(category='success',expected_stdout='xxx\n');stdout=dict(status=0,stdout='xxx\n',stderr='')
  self.assertEqual(errors(c,self.clean,stdout,SOURCE),[])
  for bad in [dict(stdout,stderr=' '),dict(stdout,stdout=' xxx\n'),dict(stdout,stdout='xxx'),dict(stdout,status=1),dict(stdout,stdout='xxx\n\n')]:
   with self.subTest(bad=bad):self.assertTrue(errors(c,self.clean,bad,SOURCE))
 def test_check_must_be_clean(self):
  c=dict(category='success',expected_stdout='x\n');stdout=dict(status=0,stdout='x\n',stderr='')
  for bad in [dict(self.clean,stdout='x\n'),dict(self.clean,stderr='warning\n'),dict(self.clean,status=1)]:
   with self.subTest(bad=bad):self.assertTrue(errors(c,bad,stdout,SOURCE))
 def test_source_exact_both_stages(self):
  self.assertEqual(errors(self.case,self.rejection,self.rejection,SOURCE),[])
 def test_source_status_and_stdout(self):
  for bad in [dict(self.rejection,status=0),dict(self.rejection,status=2),dict(self.rejection,status=-11),dict(self.rejection,stdout=' ')]:
   for stage in ['check','run']:
    with self.subTest(bad=bad,stage=stage):
     args=[self.rejection,self.rejection];args[stage=='run']=bad;self.assertTrue(errors(self.case,*args,SOURCE))
 def test_diagnostic_path_line_column(self):
  exact=self.rejection['stderr']
  for bad in [exact.replace(SOURCE,'/different/reject.f90'),exact.replace(SOURCE,'reject.f90'),exact.replace(':18:',':19:'),exact.replace(':31:',':32:'),exact.replace(':18:31:',':0:0:')]:
   for stage in ['check','run']:
    with self.subTest(bad=bad,stage=stage):
     args=[self.rejection,self.rejection];args[stage=='run']=dict(self.rejection,stderr=bad);self.assertTrue(errors(self.case,*args,SOURCE))
 def test_diagnostic_message_not_substring(self):
  exact=self.rejection['stderr'];msg=self.case['diagnostic']['message']
  for bad in [exact.replace(msg,'Unrelated error'),exact.replace(msg,msg+' extra'),exact.replace(msg,'prefix '+msg),exact.replace(msg,msg.upper()),exact.replace(msg,'Unknown keyword')]:
   with self.subTest(bad=bad):self.assertTrue(errors(self.case,self.rejection,dict(self.rejection,stderr=bad),SOURCE))
 def test_diagnostic_framing(self):
  exact=self.rejection['stderr']
  for bad in [exact.rstrip('\n'),exact+'\n',exact+exact,'noise\n'+exact,exact+'noise\n',exact.replace(': Unknown',':Unknown'),exact.replace('\n','\r\n')]:
   with self.subTest(bad=bad):self.assertTrue(errors(self.case,dict(self.rejection,stderr=bad),self.rejection,SOURCE))
 def test_path_spoof(self):
  msg=self.case['diagnostic']['message'];bad=dict(self.rejection,stderr=f'/tmp/{msg}.f90:18:31: unrelated\n')
  self.assertTrue(errors(self.case,bad,bad,SOURCE))
 def test_runtime_exact_and_phase(self):
  c=dict(category='runtime',expected_stdout='',diagnostic=dict(phase='runtime',status=2,line=19,column=13,message='REPEAT NCOPIES must be nonnegative'));stdout=dict(status=2,stdout='',stderr=diagnostic(c,SOURCE))
  self.assertEqual(errors(c,self.clean,stdout,SOURCE),[])
  for bad in [dict(stdout,status=1),dict(stdout,status=0),dict(stdout,stdout=' '),dict(stdout,stderr=stdout['stderr']+'noise')]:
   with self.subTest(bad=bad):self.assertTrue(errors(c,self.clean,bad,SOURCE))
  self.assertTrue(errors(c,dict(stdout,status=1),stdout,SOURCE))
 def test_manifest_phase_guard(self):
  for key,value in [('phase','runtime'),('status',2)]:
   c=copy.deepcopy(self.case);c['diagnostic'][key]=value
   with self.subTest(key=key):self.assertTrue(errors(c,self.rejection,self.rejection,SOURCE))
 def test_wrong_stage_diagnostic(self):
  self.assertTrue(errors(self.case,self.clean,self.rejection,SOURCE))
  c=dict(category='runtime',expected_stdout='',diagnostic=dict(self.case['diagnostic'],phase='runtime',status=2))
  self.assertTrue(errors(c,self.rejection,dict(self.rejection,status=2),SOURCE))
 def test_crash(self):
  for crash in ['Backtrace:','Segmentation fault','Internal compiler error','Fortran runtime error: Index']:
   bad=dict(self.rejection,stderr=self.rejection['stderr']+crash)
   with self.subTest(crash=crash):self.assertTrue(errors(self.case,bad,bad,SOURCE))
 def test_unknown_category(self):
  self.assertTrue(errors(dict(category='typo'),self.clean,self.clean,SOURCE))
class GnuHarness(unittest.TestCase):
 def test_documented_warning_exact(self):
  c={'oracle':'compile','gnu_compile_stderr':'{source}: warning\n'}
  q={'status':0,'stdout':'','stderr':SOURCE+': warning\n'}
  self.assertEqual(gnu_errors(c,q,SOURCE),[])
  for bad in [dict(q,status=1),dict(q,stdout='noise'),dict(q,stderr='unrelated warning\n'),dict(q,stderr=q['stderr']+'extra')]:
   with self.subTest(bad=bad):self.assertTrue(gnu_errors(c,bad,SOURCE))
 def test_clean_compile(self):
  c={'oracle':'execute'};q={'status':0,'stdout':'','stderr':''}
  self.assertEqual(gnu_errors(c,q,SOURCE),[])
  self.assertTrue(gnu_errors(c,dict(q,stderr='warning'),SOURCE))
 def test_expected_reject_is_not_crash_or_success(self):
  c={'oracle':'reject'};q={'status':1,'stdout':'','stderr':'Error: invalid source\n'}
  self.assertEqual(gnu_errors(c,q,SOURCE),[])
  for bad in [dict(q,status=0),dict(q,status=-11),dict(q,stderr='Internal compiler error')]:
   with self.subTest(bad=bad):self.assertTrue(gnu_errors(c,bad,SOURCE))
if __name__=='__main__':unittest.main()
