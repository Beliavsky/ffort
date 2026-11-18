#!/usr/bin/env python3
import copy,unittest
from run_tests import errors,expected_diagnostic
SOURCE='/portable root/cases/reject.f90'
class Harness(unittest.TestCase):
 def setUp(self):
  self.case=dict(category='reject',diagnostic=dict(phase='source',status=1,line=18,column=31,message='Unknown keyword or excess actual argument: n'))
  self.rejection=dict(code=1,out='',err=expected_diagnostic(self.case,SOURCE))
  self.clean=dict(code=0,out='',err='')
 def test_success_exact(self):
  c=dict(category='success',expected_stdout='xxx\n');out=dict(code=0,out='xxx\n',err='')
  self.assertEqual(errors(c,self.clean,out,SOURCE),[])
  for bad in [dict(out,err=' '),dict(out,out=' xxx\n'),dict(out,out='xxx'),dict(out,code=1),dict(out,out='xxx\n\n')]:
   with self.subTest(bad=bad):self.assertTrue(errors(c,self.clean,bad,SOURCE))
 def test_check_must_be_clean(self):
  c=dict(category='success',expected_stdout='x\n');out=dict(code=0,out='x\n',err='')
  for bad in [dict(self.clean,out='x\n'),dict(self.clean,err='warning\n'),dict(self.clean,code=1)]:
   with self.subTest(bad=bad):self.assertTrue(errors(c,bad,out,SOURCE))
 def test_source_exact_both_stages(self):
  self.assertEqual(errors(self.case,self.rejection,self.rejection,SOURCE),[])
 def test_source_status_and_stdout(self):
  for bad in [dict(self.rejection,code=0),dict(self.rejection,code=2),dict(self.rejection,code=-11),dict(self.rejection,out=' ')]:
   for stage in ['check','run']:
    with self.subTest(bad=bad,stage=stage):
     args=[self.rejection,self.rejection];args[stage=='run']=bad;self.assertTrue(errors(self.case,*args,SOURCE))
 def test_diagnostic_path_line_column(self):
  exact=self.rejection['err']
  for bad in [exact.replace(SOURCE,'/different/reject.f90'),exact.replace(SOURCE,'reject.f90'),exact.replace(':18:',':19:'),exact.replace(':31:',':32:'),exact.replace(':18:31:',':0:0:')]:
   for stage in ['check','run']:
    with self.subTest(bad=bad,stage=stage):
     args=[self.rejection,self.rejection];args[stage=='run']=dict(self.rejection,err=bad);self.assertTrue(errors(self.case,*args,SOURCE))
 def test_diagnostic_message_not_substring(self):
  exact=self.rejection['err'];msg=self.case['diagnostic']['message']
  for bad in [exact.replace(msg,'Unrelated error'),exact.replace(msg,msg+' extra'),exact.replace(msg,'prefix '+msg),exact.replace(msg,msg.upper()),exact.replace(msg,'Unknown keyword')]:
   with self.subTest(bad=bad):self.assertTrue(errors(self.case,self.rejection,dict(self.rejection,err=bad),SOURCE))
 def test_diagnostic_framing(self):
  exact=self.rejection['err']
  for bad in [exact.rstrip('\n'),exact+'\n',exact+exact,'noise\n'+exact,exact+'noise\n',exact.replace(': Unknown',':Unknown'),exact.replace('\n','\r\n')]:
   with self.subTest(bad=bad):self.assertTrue(errors(self.case,dict(self.rejection,err=bad),self.rejection,SOURCE))
 def test_path_spoof(self):
  msg=self.case['diagnostic']['message'];bad=dict(self.rejection,err=f'/tmp/{msg}.f90:18:31: unrelated\n')
  self.assertTrue(errors(self.case,bad,bad,SOURCE))
 def test_runtime_exact_and_phase(self):
  c=dict(category='runtime',expected_stdout='',diagnostic=dict(phase='runtime',status=2,line=19,column=13,message='REPEAT NCOPIES must be nonnegative'));out=dict(code=2,out='',err=expected_diagnostic(c,SOURCE))
  self.assertEqual(errors(c,self.clean,out,SOURCE),[])
  for bad in [dict(out,code=1),dict(out,code=0),dict(out,out=' '),dict(out,err=out['err']+'noise')]:
   with self.subTest(bad=bad):self.assertTrue(errors(c,self.clean,bad,SOURCE))
  self.assertTrue(errors(c,dict(out,code=1),out,SOURCE))
 def test_manifest_phase_guard(self):
  for key,value in [('phase','runtime'),('status',2)]:
   c=copy.deepcopy(self.case);c['diagnostic'][key]=value
   with self.subTest(key=key):self.assertTrue(errors(c,self.rejection,self.rejection,SOURCE))
 def test_wrong_stage_diagnostic(self):
  self.assertTrue(errors(self.case,self.clean,self.rejection,SOURCE))
  c=dict(category='runtime',expected_stdout='',diagnostic=dict(self.case['diagnostic'],phase='runtime',status=2))
  self.assertTrue(errors(c,self.rejection,dict(self.rejection,code=2),SOURCE))
 def test_crash(self):
  for crash in ['Backtrace:','Segmentation fault','Internal compiler error','Fortran runtime error: Index']:
   bad=dict(self.rejection,err=self.rejection['err']+crash)
   with self.subTest(crash=crash):self.assertTrue(errors(self.case,bad,bad,SOURCE))
 def test_unknown_category(self):
  self.assertTrue(errors(dict(category='typo'),self.clean,self.clean,SOURCE))
if __name__=='__main__':unittest.main()
