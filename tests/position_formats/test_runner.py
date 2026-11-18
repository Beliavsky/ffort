#!/usr/bin/env python3
import copy,hashlib,json,shutil,subprocess,sys,tempfile,unittest
from pathlib import Path
from run_tests import matches,ROOT
class RunnerTests(unittest.TestCase):
 def setUp(self):
  self.source=Path('/tmp/example.f90');self.case=dict(kind='pass',gnu='pass',expected_stdout=' A  \n')
  self.check=dict(code=0,out='',err='');self.actual=dict(code=0,out=' A  \n',err='');self.compiled=self.check.copy();self.oracle=self.actual.copy()
 def ok(self,**kw):
  v=dict(case=self.case,source=self.source,check=self.check,actual=self.actual,compiled=self.compiled,oracle=self.oracle);v.update(kw);return matches(**v)
 def test_exact_success(self):self.assertTrue(self.ok())
 def test_significant_whitespace(self):
  for out in ['A\n',' A\n',' A  ',' A  \n\n','\tA  \n']:
   with self.subTest(out=out):self.assertFalse(self.ok(actual=dict(code=0,out=out,err='')))
 def test_no_numeric_normalization(self):
  c=dict(self.case,expected_stdout='-0.0\n')
  self.assertFalse(self.ok(case=c,actual=dict(code=0,out='0.0\n',err=''),oracle=dict(code=0,out='-0.0\n',err='')))
 def test_clean_check_required(self):
  for x in [dict(code=0,out=' ',err=''),dict(code=0,out='',err=' '),dict(code=1,out='',err='bad')]:self.assertFalse(self.ok(check=x))
 def test_success_stderr_or_status(self):
  for x in [dict(code=0,out=self.actual['out'],err=' '),dict(code=2,out=self.actual['out'],err='')]:self.assertFalse(self.ok(actual=x))
 def rejected(self):
  self.case=dict(kind='reject',gnu='pass',diagnostic='bad position');self.check=dict(code=1,out='',err='/tmp/example.f90:3:1: bad position\n');self.actual=self.check.copy();self.oracle=None
 def test_precise_rejection(self):self.rejected();self.assertTrue(self.ok())
 def test_rejection_diagnostic_identity(self):
  self.rejected()
  for err in ['', 'unrelated\n','/tmp/other.f90:3:1: bad position\n','/tmp/example.f90:0:0: bad position\n','/tmp/example.f90:3:1: different\n',self.actual['err']+'extra\n']:
   with self.subTest(err=err):self.assertFalse(self.ok(actual=dict(code=1,out='',err=err)))
 def test_both_rejection_phases(self):
  self.rejected();self.assertFalse(self.ok(check=dict(code=1,out='',err='other\n')));self.assertFalse(self.ok(check=dict(code=0,out='',err='')))
 def test_rejection_stdout_status(self):
  self.rejected()
  for x in [dict(code=1,out=' ',err=self.actual['err']),dict(code=2,out='',err=self.actual['err'])]:self.assertFalse(self.ok(actual=x))
 def test_runtime_prefix_exact(self):
  self.rejected();self.case.update(kind='runtime',prefix='SAFE');self.check=dict(code=0,out='',err='');self.actual.update(code=2,out='SAFE');self.assertTrue(self.ok())
  for out in ['','SAFE\n','SAFEbad']:self.assertFalse(self.ok(actual=dict(self.actual,out=out)))
 def test_host_crash_markers(self):
  self.rejected()
  for marker in ['Backtrace','Traceback','Fortran runtime error','internal compiler error','SIGSEGV','AddressSanitizer','ICE']:
   c=dict(self.case,diagnostic=marker);r=dict(code=1,out='',err='/tmp/example.f90:3:1: '+marker+'\n');self.assertFalse(self.ok(case=c,check=r,actual=r))
 def test_compile_only_not_execution(self):
  self.rejected();self.assertTrue(self.ok());self.assertFalse(self.ok(oracle=dict(code=0,out='',err='')))
 def test_compile_rejection_distinction(self):
  self.rejected();self.case['gnu']='fail';self.assertFalse(self.ok());self.assertTrue(self.ok(compiled=dict(code=1,out='',err='source invalid')));self.assertFalse(self.ok(compiled=dict(code=1,out='',err='internal compiler error')))
 def test_documented_oracle_discrepancy_requires_both(self):
  c=dict(self.case,gnu_expected_stdout='GNU\n');self.assertTrue(self.ok(case=c,oracle=dict(code=0,out='GNU\n',err='')))
  self.assertFalse(self.ok(case=c));self.assertFalse(self.ok(case=c,actual=dict(code=0,out='wrong\n',err=''),oracle=dict(code=0,out='GNU\n',err='')))
 def test_original_provenance(self):
  from check_provenance import check
  check()
 def test_generator_reproducible(self):
  with tempfile.TemporaryDirectory(prefix='position-generation-') as folder:
   p=Path(folder);shutil.copy2(ROOT/'generate_cases.py',p/'generate_cases.py');(p/'cases').mkdir()
   for name in ('demo_cos','demo_cosd'):shutil.copy2(ROOT/'cases'/(name+'.f90'),p/'cases'/(name+'.f90'))
   r=subprocess.run([sys.executable,str(p/'generate_cases.py')],capture_output=True);self.assertEqual(r.returncode,0,r.stderr)
   self.assertEqual((p/'manifest.json').read_bytes(),(ROOT/'manifest.json').read_bytes())
   for f in (ROOT/'cases').glob('*.f90'):self.assertEqual(f.read_bytes(),(p/'cases'/f.name).read_bytes())
if __name__=='__main__':unittest.main()
