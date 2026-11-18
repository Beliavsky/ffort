"""Adversarial exact stream/phase/provenance policy checks; no compiler needed."""
import copy,unittest
from pathlib import Path
import run_tests as runner
record=runner.process_record
class RunnerContract(unittest.TestCase):
 def setUp(self):
  self.path=Path('/portable path/case.f90')
  self.case=dict(stage='success',gnu='run',expected='1\n',gnu_expected='1\n',diagnostic=None,gnu_stderr='')
  self.empty=record(code=0,out='',err='');self.success=record(code=0,out='1\n',err='')
 def test_valid_success(self):
  self.assertEqual(runner.candidate_errors(self.case,self.path,self.empty,self.success),[])
  self.assertEqual(runner.gnu_errors(self.case,self.path,self.empty,self.success),[])
 def test_no_numeric_or_whitespace_normalization(self):
  for wrong in ('1',' 1\n','1 \n','1\n\n','1.0\n','01\n','2\n','1e0\n','1\r\n','1\x00\n'):
   with self.subTest(wrong=repr(wrong)):
    actual=dict(self.success,out=wrong)
    self.assertTrue(runner.candidate_errors(self.case,self.path,self.empty,actual))
    self.assertTrue(runner.gnu_errors(self.case,self.path,self.empty,actual))
 def test_tiny_zero_integer_and_character_are_distinct(self):
  for expected,wrong in [('1e-310\n','0\n'),('-0.0\n','0.0\n'),('9007199254740993\n','9007199254740992\n'),('a b \n','a b\n'),('Inf\n','NaN\n'),('1D0\n','1E0\n')]:
   with self.subTest(expected=expected):
    case=dict(self.case,expected=expected,gnu_expected=expected)
    self.assertTrue(runner.candidate_errors(case,self.path,self.empty,dict(self.success,out=wrong)))
    self.assertTrue(runner.gnu_errors(case,self.path,self.empty,dict(self.success,out=wrong)))
 def test_success_streams_truly_empty(self):
  for noise in (' ','\n','warning\n','\x00'):
   with self.subTest(noise=repr(noise)):
    self.assertTrue(runner.candidate_errors(self.case,self.path,dict(self.empty,out=noise),self.success))
    self.assertTrue(runner.candidate_errors(self.case,self.path,dict(self.empty,err=noise),self.success))
    self.assertTrue(runner.candidate_errors(self.case,self.path,self.empty,dict(self.success,err=noise)))
    self.assertTrue(runner.gnu_errors(self.case,self.path,dict(self.empty,err=noise),self.success))
 def test_exact_negative_stage_location_and_message(self):
  for stage,code in [('runtime',2),('compile',1)]:
   case=dict(self.case,stage=stage,expected='',diagnostic='7:12: bounded rejection')
   rejected=record(code=code,out='',err=str(self.path)+':7:12: bounded rejection\n')
   check=self.empty if stage=='runtime' else rejected
   self.assertEqual(runner.candidate_errors(case,self.path,check,rejected),[])
   for changed in [dict(rejected,code=0),dict(rejected,code=-11),dict(rejected,out='SAFE\n'),dict(rejected,err=rejected['err'].replace('7:12','7:13')),dict(rejected,err=rejected['err'].replace('case.f90','other.f90')),dict(rejected,err=rejected['err']+'\n'),dict(rejected,err='bounded rejection\n')]:
    with self.subTest(stage=stage,changed=changed):self.assertTrue(runner.candidate_errors(case,self.path,check,changed))
 def test_unpinned_negative_fails_closed(self):
  for diag in (None,'','bounded error','0:2: error','1:0: error','1:2: error\nextra'):
   case=dict(self.case,stage='compile',diagnostic=diag)
   self.assertTrue(runner.candidate_errors(case,self.path,self.empty,self.success))
 def test_gnu_warning_pin_exact(self):
  case=dict(self.case,gnu_stderr='{source}:4:3:\nWarning: pinned extension\n')
  comp=record(code=0,out='',err=str(self.path)+':4:3:\nWarning: pinned extension\n')
  self.assertEqual(runner.gnu_errors(case,self.path,comp,self.success),[])
  for err in ('',comp['err']+'\n',comp['err']+'Warning: unrelated\n',comp['err'].replace('pinned','arbitrary')):
   self.assertTrue(runner.gnu_errors(case,self.path,dict(comp,err=err),self.success))
 def test_gnu_constraint_and_compile_only(self):
  case=dict(self.case,gnu='reject',gnu_stderr='{source}:4:3: Error: constraint\n')
  comp=record(code=1,out='',err=str(self.path)+':4:3: Error: constraint\n')
  self.assertEqual(runner.gnu_errors(case,self.path,comp,None),[])
  self.assertTrue(runner.gnu_errors(case,self.path,dict(comp,code=0),None))
  self.assertTrue(runner.gnu_errors(case,self.path,comp,self.success))
  case=dict(self.case,gnu='compile')
  self.assertEqual(runner.gnu_errors(case,self.path,self.empty,None),[])
  self.assertTrue(runner.gnu_errors(case,self.path,self.empty,self.success))
 def test_crashes_never_pinned_as_gnu_rejection(self):
  for marker in ('Backtrace','Internal compiler error','Fortran runtime error','segmentation fault','SIGSEGV','SIGABRT','TIMEOUT'):
   case=dict(self.case,gnu='reject',gnu_stderr=marker)
   self.assertTrue(runner.gnu_errors(case,self.path,record(code=1,out='',err=marker),None))
 def test_absent_and_unknown_contract_fail(self):
  case=copy.deepcopy(self.case);del case['gnu_stderr']
  self.assertTrue(runner.gnu_errors(case,self.path,self.empty,self.success))
  self.assertTrue(runner.gnu_errors(dict(self.case,gnu='unknown'),self.path,self.empty,self.success))
  self.assertTrue(runner.candidate_errors(dict(self.case,stage='unknown'),self.path,self.empty,self.success))
 def test_original_provenance(self):self.assertTrue(runner.check_provenance())
if __name__=='__main__':unittest.main()
