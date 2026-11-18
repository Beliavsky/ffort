import unittest
from strict_contract import candidate_errors,gnu_errors,stage_errors,version_errors
class ContractTests(unittest.TestCase):
 def setUp(self):
  self.src='/tmp/exact.f90';self.ok=dict(status=0,stdout='',stderr='');self.c=dict(name='x',category='success',gnu='run',expected_stdout=' Ab  \n');self.out=dict(self.ok,stdout=self.c['expected_stdout'])
 def test_exact_success(self):self.assertEqual(candidate_errors(self.c,self.ok,self.out,self.src),[])
 def test_check_stdout(self):self.assertTrue(candidate_errors(self.c,dict(self.ok,stdout='x'),self.out,self.src))
 def test_check_stderr(self):self.assertTrue(candidate_errors(self.c,dict(self.ok,stderr='x'),self.out,self.src))
 def test_check_status(self):self.assertTrue(candidate_errors(self.c,dict(self.ok,status=1),self.out,self.src))
 def test_output_case(self):self.assertTrue(candidate_errors(self.c,self.ok,dict(self.out,stdout=' ab  \n'),self.src))
 def test_output_trailing_spaces(self):self.assertTrue(candidate_errors(self.c,self.ok,dict(self.out,stdout=' Ab\n'),self.src))
 def test_output_newline(self):self.assertTrue(candidate_errors(self.c,self.ok,dict(self.out,stdout=' Ab  '),self.src))
 def test_success_stderr(self):self.assertTrue(candidate_errors(self.c,self.ok,dict(self.out,stderr='warning'),self.src))
 def test_success_status(self):self.assertTrue(candidate_errors(self.c,self.ok,dict(self.out,status=2),self.src))
 def neg(self,phase='source'):
  c=dict(self.c,category='reject'if phase=='source'else'runtime',gnu='compile',expected_stdout=''if phase=='source'else'SAFE\n',diagnostic=dict(phase=phase,status=1 if phase=='source'else 2,line=8,column=4,message='exact failure'))
  x=dict(status=c['diagnostic']['status'],stdout=c['expected_stdout'],stderr=self.src+':8:4: exact failure\n');return c,x
 def test_exact_source(self):
  c,x=self.neg();self.assertEqual(candidate_errors(c,x,x,self.src),[])
 def test_exact_runtime(self):
  c,x=self.neg('runtime');self.assertEqual(candidate_errors(c,self.ok,x,self.src),[])
 def test_unpinned_rejected(self):
  with self.assertRaises(ValueError):candidate_errors(dict(self.c,category='reject'),self.ok,self.ok,self.src)
 def test_bad_source_phase(self):
  c,x=self.neg();c['diagnostic']['phase']='runtime'
  with self.assertRaises(ValueError):candidate_errors(c,x,x,self.src)
 def test_negative_path(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,x,x,'/tmp/other.f90'))
 def test_negative_line(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,x,dict(x,stderr=x['stderr'].replace(':8:',':9:')),self.src))
 def test_negative_column(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,x,dict(x,stderr=x['stderr'].replace(':4:',':5:')),self.src))
 def test_negative_message(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,x,dict(x,stderr=x['stderr'].replace('exact','other')),self.src))
 def test_negative_newline(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,x,dict(x,stderr=x['stderr'].rstrip()),self.src))
 def test_negative_extra(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,x,dict(x,stderr=x['stderr']+'extra\n'),self.src))
 def test_negative_phase(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,self.ok,x,self.src))
 def test_negative_status(self):
  c,x=self.neg()
  for status in [0,2,-11,None]:self.assertTrue(candidate_errors(c,x,dict(x,status=status),self.src))
 def test_negative_stdout(self):
  c,x=self.neg();self.assertTrue(candidate_errors(c,x,dict(x,stdout='partial'),self.src))
 def test_runtime_prefix(self):
  c,x=self.neg('runtime');self.assertTrue(candidate_errors(c,self.ok,dict(x,stdout=''),self.src))
 def test_crash_not_expected(self):
  c,x=self.neg();c['diagnostic']['message']='Backtrace';x['stderr']=self.src+':8:4: Backtrace\n';self.assertTrue(candidate_errors(c,x,x,self.src))
 def test_gnu_exact(self):self.assertEqual(gnu_errors(self.c,self.ok,self.out,self.src),[])
 def test_gnu_warning(self):self.assertTrue(gnu_errors(self.c,dict(self.ok,stderr='warning'),self.out,self.src))
 def test_gnu_expected_warning(self):
  c=dict(self.c,gnu_compile_stderr='{source}: expected warning\n');self.assertEqual(gnu_errors(c,dict(self.ok,stderr=self.src+': expected warning\n'),self.out,self.src),[])
 def test_gnu_compile_only(self):
  c=dict(self.c,gnu='compile');self.assertEqual(gnu_errors(c,self.ok,None,self.src),[]);self.assertTrue(gnu_errors(c,self.ok,self.out,self.src))
 def test_gnu_reject(self):
  c=dict(self.c,gnu='reject');self.assertEqual(gnu_errors(c,dict(status=1,stdout='',stderr='compile error'),None,self.src),[]);self.assertTrue(gnu_errors(c,self.ok,None,self.src))


class StageSchemaTests(unittest.TestCase):
 def setUp(self):
  self.src='/tmp/exact.f90';self.ok=dict(status=0,stdout='',stderr='');self.out=dict(self.ok,stdout='ok\n')
  self.c=dict(name='x',category='success',gnu='run',expected_stdout='ok\n')
  self.source_case=dict(self.c,category='reject',expected_stdout='',diagnostic=dict(phase='source',status=1,line=8,column=4,message='expected failure'))
  self.source_record=dict(status=1,stdout='',stderr=self.src+':8:4: expected failure\n')
  self.runtime_case=dict(self.c,category='runtime',expected_stdout='SAFE\n',diagnostic=dict(phase='runtime',status=2,line=8,column=4,message='expected failure'))
  self.runtime_record=dict(status=2,stdout='SAFE\n',stderr=self.src+':8:4: expected failure\n')
 def stages(self):
  return [
   ('candidate success check',self.ok,lambda x:candidate_errors(self.c,x,self.out,self.src)),
   ('candidate success run',self.out,lambda x:candidate_errors(self.c,self.ok,x,self.src)),
   ('candidate source check',self.source_record,lambda x:candidate_errors(self.source_case,x,self.source_record,self.src)),
   ('candidate source run',self.source_record,lambda x:candidate_errors(self.source_case,self.source_record,x,self.src)),
   ('candidate runtime check',self.ok,lambda x:candidate_errors(self.runtime_case,x,self.runtime_record,self.src)),
   ('candidate runtime run',self.runtime_record,lambda x:candidate_errors(self.runtime_case,self.ok,x,self.src)),
   ('GNU compile run mode',self.ok,lambda x:gnu_errors(self.c,x,self.out,self.src)),
   ('GNU execution',self.out,lambda x:gnu_errors(self.c,self.ok,x,self.src)),
   ('GNU compile only',self.ok,lambda x:gnu_errors(dict(self.c,gnu='compile'),x,None,self.src)),
   ('GNU source reject',dict(status=1,stdout='',stderr='compile error'),lambda x:gnu_errors(dict(self.c,gnu='reject'),x,None,self.src)),
   ('candidate version before',dict(self.ok,stdout='fortfront-interpreter 0.52.0\n'),lambda x:version_errors(x,'fortfront-interpreter ','candidate version before')),
   ('candidate version after',dict(self.ok,stdout='fortfront-interpreter 0.52.0\n'),lambda x:version_errors(x,'fortfront-interpreter ','candidate version after')),
   ('GNU version',dict(self.ok,stdout='GNU Fortran 14.2.0\n'),lambda x:version_errors(x,'GNU Fortran','GNU version'))]
 def poison(self,change):
  for name,good,check in self.stages():
   with self.subTest(stage=name):self.assertTrue(check(change(dict(good))))
 def test_all_stage_controls(self):
  for name,good,check in self.stages():
   with self.subTest(stage=name):self.assertEqual(check(good),[])
 def test_all_stage_false_timeout_controls(self):
  for name,good,check in self.stages():
   with self.subTest(stage=name):self.assertEqual(check(dict(good,timeout=False)),[])
 def test_missing_status(self):self.poison(lambda x:{k:v for k,v in x.items()if k!='status'})
 def test_status_false(self):self.poison(lambda x:dict(x,status=False))
 def test_status_true(self):self.poison(lambda x:dict(x,status=True))
 def test_status_float(self):self.poison(lambda x:dict(x,status=float(x['status'])))
 def test_status_string(self):self.poison(lambda x:dict(x,status=str(x['status'])))
 def test_status_null(self):self.poison(lambda x:dict(x,status=None))
 def test_status_negative(self):self.poison(lambda x:dict(x,status=-11))
 def test_missing_stdout(self):self.poison(lambda x:{k:v for k,v in x.items()if k!='stdout'})
 def test_missing_stderr(self):self.poison(lambda x:{k:v for k,v in x.items()if k!='stderr'})
 def test_stdout_null(self):self.poison(lambda x:dict(x,stdout=None))
 def test_stderr_null(self):self.poison(lambda x:dict(x,stderr=None))
 def test_stdout_bool(self):self.poison(lambda x:dict(x,stdout=False))
 def test_stderr_list(self):self.poison(lambda x:dict(x,stderr=[]))
 def test_stdout_bytes(self):self.poison(lambda x:dict(x,stdout=b''))
 def test_timeout_true(self):self.poison(lambda x:dict(x,timeout=True))
 def test_timeout_integer(self):self.poison(lambda x:dict(x,timeout=0))
 def test_timeout_float(self):self.poison(lambda x:dict(x,timeout=0.0))
 def test_timeout_string(self):self.poison(lambda x:dict(x,timeout='false'))
 def test_timeout_null(self):self.poison(lambda x:dict(x,timeout=None))
 def test_record_null(self):self.poison(lambda x:None)
 def test_record_list(self):self.poison(lambda x:[])
 def test_record_empty(self):self.poison(lambda x:{})
 def test_stdout_replacement(self):self.poison(lambda x:dict(x,stdout=x['stdout']+'\ufffd'))
 def test_stderr_replacement(self):self.poison(lambda x:dict(x,stderr=x['stderr']+'\ufffd'))
 def test_stdout_surrogate(self):self.poison(lambda x:dict(x,stdout=x['stdout']+'\udc80'))
 def test_stderr_surrogate(self):self.poison(lambda x:dict(x,stderr=x['stderr']+'\ud800'))
 def test_crash_each_marker_each_stream(self):
  from strict_contract import CRASH
  for marker in CRASH:
   for stream in ['stdout','stderr']:
    with self.subTest(marker=marker,stream=stream):self.poison(lambda x:dict(x,**{stream:x[stream]+marker.upper()}))
 def test_gnu_crash_cannot_match_expected_stdout(self):
  for marker in ['Backtrace','core dumped','TIMEOUT']:
   with self.subTest(marker=marker):self.assertTrue(gnu_errors(dict(self.c,expected_stdout=marker),self.ok,dict(self.out,stdout=marker),self.src))
 def test_version_nonzero_status(self):
  for status in [1,2]:self.assertTrue(version_errors(dict(self.ok,status=status,stdout='GNU Fortran 14\n'),'GNU Fortran'))
 def test_version_wrong_banner(self):self.assertTrue(version_errors(dict(self.ok,stdout='not GNU\n'),'GNU Fortran'))
 def test_version_diagnostic(self):self.assertTrue(version_errors(dict(self.ok,stdout='GNU Fortran 14\n',stderr='warning'),'GNU Fortran'))
 def test_compile_only_empty_run_not_absence(self):self.assertTrue(gnu_errors(dict(self.c,gnu='compile'),self.ok,{},self.src))
 def test_reject_empty_run_not_absence(self):self.assertTrue(gnu_errors(dict(self.c,gnu='reject'),dict(status=1,stdout='',stderr='error'),{},self.src))
 def test_schema_extra_metadata_allowed(self):self.assertEqual(stage_errors(dict(self.ok,argv=['cc','--version'])),[])
 def test_valid_utf8_true_controls(self):
  for name,good,check in self.stages():
   with self.subTest(stage=name):self.assertEqual(check(dict(good,valid_utf8=True)),[])
 def test_valid_utf8_false(self):self.poison(lambda x:dict(x,valid_utf8=False))
 def test_valid_utf8_zero(self):self.poison(lambda x:dict(x,valid_utf8=0))
 def test_valid_utf8_one(self):self.poison(lambda x:dict(x,valid_utf8=1))
 def test_valid_utf8_float(self):self.poison(lambda x:dict(x,valid_utf8=1.0))
 def test_valid_utf8_string(self):self.poison(lambda x:dict(x,valid_utf8='true'))
 def test_valid_utf8_null(self):self.poison(lambda x:dict(x,valid_utf8=None))
 def test_gnu_required_rejection_needs_diagnostic(self):self.assertTrue(gnu_errors(dict(self.c,gnu='reject'),dict(status=1,stdout='',stderr=''),None,self.src))
 def test_gnu_required_rejection_whitespace_not_diagnostic(self):self.assertTrue(gnu_errors(dict(self.c,gnu='reject'),dict(status=1,stdout='',stderr=' \t\n'),None,self.src))

if __name__=='__main__':unittest.main()
