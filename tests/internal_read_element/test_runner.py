"""Pure contract tests. These do not build or execute the interpreter."""
import base64,copy,json,tempfile,unittest
from pathlib import Path
import run_tests as r

class Contract(unittest.TestCase):
 def setUp(self):
  self.case=dict(stage='success',expected='A  \n\nB\t\n',diagnostic=None,gnu='run',gnu_stderr='',gnu_expected='A  \n\nB\t\n')
  self.source=Path('/exact/path/test.f90');self.check=r.process_record(0);self.run=r.process_record(0,self.case['expected'])
 def bad(self,check=None,ran=None,case=None):
  self.assertTrue(r.candidate_errors(case or self.case,self.source,check or self.check,ran or self.run))
 def test_exact_positive(self):self.assertEqual(r.candidate_errors(self.case,self.source,self.check,self.run),[])
 def test_padding(self):self.bad(ran=r.process_record(0,'A\n\nB\t\n'))
 def test_blank_record(self):self.bad(ran=r.process_record(0,'A  \nB\t\n'))
 def test_tab(self):self.bad(ran=r.process_record(0,'A  \n\nB \n'))
 def test_final_newline(self):self.bad(ran=r.process_record(0,self.case['expected'][:-1]))
 def test_success_stderr_whitespace(self):self.bad(ran=r.process_record(0,self.case['expected'],' '))
 def test_check_stdout_whitespace(self):self.bad(check=r.process_record(0,'\n'))
 def test_boolean_code(self):
  x=copy.deepcopy(self.check);x['code']=False;self.bad(check=x)
 def test_float_code(self):
  x=copy.deepcopy(self.check);x['code']=0.0;self.bad(check=x)
 def test_signal(self):self.bad(check=r.process_record(-11,termination='signal'))
 def test_timeout_keeps_partial(self):
  x=r.process_record(None,b'partial',b'failure',termination='timeout',error='deadline');self.assertEqual(base64.b64decode(x['stdout_b64']),b'partial');self.bad(check=x)
 def test_spawn_error_distinct(self):
  x=r.process_record(None,termination='spawn-error',error='missing');self.bad(check=x);self.assertEqual(x['termination'],'spawn-error')
 def test_invalid_utf8(self):self.bad(ran=r.process_record(0,b'\xff'))
 def test_schema_extra(self):
  x=copy.deepcopy(self.run);x['extra']=0;self.bad(ran=x)
 def test_schema_missing(self):
  x=copy.deepcopy(self.run);del x['utf8'];self.bad(ran=x)
 def test_raw_output_disagreement(self):
  x=copy.deepcopy(self.run);x['stdout_b64']=base64.b64encode(b'changed').decode();self.bad(ran=x)
 def test_digest_disagreement(self):
  x=copy.deepcopy(self.run);x['stderr_sha256']='0'*64;self.bad(ran=x)
 def test_unpinned_fails_closed(self):
  x=dict(self.case,stage='compile',expected='');self.bad(case=x,check=r.process_record(1,err='not pinned'),ran=r.process_record(1,err='not pinned'))
 def test_exact_negative_and_location(self):
  c=dict(self.case,stage='runtime',expected='',diagnostic='5:12: array subscript out of bounds');good=r.process_record(2,err=str(self.source)+':'+c['diagnostic']+'\n')
  self.assertEqual(r.candidate_errors(c,self.source,self.check,good),[])
  self.bad(case=c,ran=r.process_record(2,err=str(self.source)+':5:13: array subscript out of bounds\n'))
 def test_wrong_path(self):
  c=dict(self.case,stage='runtime',expected='',diagnostic='5:12: error');self.bad(case=c,ran=r.process_record(2,err='/wrong/test.f90:5:12: error\n'))
 def test_wrong_stage(self):
  c=dict(self.case,stage='runtime',expected='',diagnostic='5:12: error');x=r.process_record(1,err=str(self.source)+':5:12: error\n');self.bad(case=c,check=x,ran=x)
 def test_pinned_crash_rejected(self):
  c=dict(self.case,stage='runtime',expected='',diagnostic='5:12: SIGSEGV');self.bad(case=c,ran=r.process_record(2,err=str(self.source)+':5:12: SIGSEGV\n'))
 def test_gnu_exact(self):self.assertEqual(r.gnu_errors(self.case,self.source,self.check,self.run),[])
 def test_gnu_compile_only_not_executed(self):self.assertTrue(r.gnu_errors(dict(self.case,gnu='compile'),self.source,self.check,self.run))
 def test_gnu_constraint_exact(self):
  c=dict(self.case,gnu='reject',gnu_stderr='{source}:5: Error\n');x=r.process_record(1,err=str(self.source)+':5: Error\n')
  self.assertEqual(r.gnu_errors(c,self.source,x,None),[]);self.assertTrue(r.gnu_errors(c,self.source,r.process_record(1,err='Error\n'),None))
 def test_identity_inventory(self):self.assertEqual(len(r.load_cases()),51);self.assertTrue(r.check_provenance())
 def test_duplicate_json(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'x';p.write_text('{"a":1,"a":2}')
   with self.assertRaises(ValueError):r.read_json(p)
 def test_existing_result(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'x';p.write_bytes(b'old')
   with self.assertRaises(ValueError):r.require_new_path(p)
   self.assertEqual(p.read_bytes(),b'old')
 def test_symlink_result_parent(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);(p/'real').mkdir();(p/'alias').symlink_to(p/'real',target_is_directory=True)
   with self.assertRaises(ValueError):r.require_new_path(p/'alias'/'new')
 def test_version_exact(self):
  x=r.process_record(0,'fortfront-interpreter 0.54.0; FortFront 9a5896a + documented local patches\n')
  self.assertEqual(r.version_errors(x,'0.54.0'),[]);self.assertTrue(r.version_errors(x,'0.53.0'))
if __name__=='__main__':unittest.main()
