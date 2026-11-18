import unittest,json,copy,tempfile,shutil,subprocess,sys
from pathlib import Path
from run_tests import compare,candidate_errors,oracle_errors,validate_cases,ROOT
class HarnessTests(unittest.TestCase):
 def setUp(self):
  self.src=Path('/tmp/p.f90');self.case=dict(category='success',expected_stdout='Ab D e  \n',gnu='run')
  self.check=dict(code=0,out='',err='');self.run=dict(code=0,out=self.case['expected_stdout'],err='')
 def test_exact_text(self):self.assertTrue(compare('Ab D e  \n','Ab D e  \n'))
 def test_case_sensitive(self):self.assertFalse(compare('ab d E  \n','Ab D e  \n'))
 def test_text_d_e_not_normalized(self):self.assertFalse(compare('de','ee'))
 def test_significant_spaces(self):
  for v in ['Ab D e\n',' Ab D e  \n','Ab\tD e  \n']:self.assertFalse(compare(v,self.case['expected_stdout']))
 def test_record_termination(self):
  for v in ['Ab D e  ','Ab D e  \r\n','Ab D e  \n\n']:self.assertFalse(compare(v,self.case['expected_stdout']))
 def test_numeric_decimal_d_exponent(self):self.assertTrue(compare(' 5.0D0  13.00E0\n','5.0 13.0\n',[0]))
 def test_signed_zero(self):
  self.assertTrue(compare('-0D0 0.00\n','-0.0 0.0\n',[0]))
  self.assertFalse(compare('0.0 0.0\n','-0.0 0.0\n',[0]))
 def test_tiny_nonzero_not_zero(self):self.assertFalse(compare('1e-9999\n','0.0\n',[0]))
 def test_exact_large_integer(self):
  self.assertTrue(compare('9007199254740993\n','9007199254740993\n',[0]))
  self.assertFalse(compare('9007199254740992\n','9007199254740993\n',[0]))
 def test_integer_spelling_not_coerced(self):
  for x in ['05','5.0','5e0']:self.assertFalse(compare(x+'\n','5\n',[0]))
 def test_nonfinite_rejected(self):
  for x in ['NaN','nan','Infinity','-Inf','1.#INF']:self.assertFalse(compare(x+'\n',x+'\n',[0]))
 def test_numeric_records_not_merged(self):self.assertFalse(compare('5.0 13.0\n','5.0\n13.0\n',[0,1]))
 def test_blank_line_does_not_short_circuit(self):self.assertFalse(compare('\nWRONG\n','\nRIGHT\n',[0]))
 def test_numeric_only_opt_in(self):self.assertFalse(compare('5.000\n','5.0\n'))
 def test_clean_check(self):
  for c in [dict(code=0,out=' ',err=''),dict(code=0,out='',err=' '),dict(code=1,out='',err='bad')]:self.assertTrue(candidate_errors(self.case,self.src,c,self.run))
 def test_success_stderr_and_code(self):
  for r in [dict(self.run,err=' '),dict(self.run,code=2)]:self.assertTrue(candidate_errors(self.case,self.src,self.check,r))
 def failure(self,category='runtime'):
  self.case.update(category=category,expected_stdout='SAFE',diagnostic='expected failure',diagnostic_line=7,diagnostic_column=3,gnu='compile')
  self.run=dict(code=2,out='SAFE',err='/tmp/p.f90:7:3: expected failure\n')
 def test_runtime_exact_prefix(self):
  self.failure();self.assertFalse(candidate_errors(self.case,self.src,self.check,self.run))
  for s in ['','SAFE\n','SAFEx']:self.assertTrue(candidate_errors(self.case,self.src,self.check,dict(self.run,out=s)))
 def test_exact_diagnostic_path_location_message(self):
  self.failure()
  for e in ['', 'other', '/tmp/other.f90:7:3: expected failure\n','/tmp/p.f90:8:3: expected failure\n','/tmp/p.f90:7:4: expected failure\n',self.run['err']+'extra\n']:self.assertTrue(candidate_errors(self.case,self.src,self.check,dict(self.run,err=e)))
 def test_rejection_both_phases(self):
  self.failure('reject');self.case['expected_stdout']='';r=dict(self.run,code=1,out='');self.assertFalse(candidate_errors(self.case,self.src,r,r));self.assertTrue(candidate_errors(self.case,self.src,self.check,r))
 def test_crash_markers(self):
  self.failure()
  for marker in ['Backtrace','Traceback','Fortran runtime error','internal compiler error','SIGSEGV','AddressSanitizer','TIMEOUT','ICE']:
   c=dict(self.case,diagnostic=marker);r=dict(self.run,err='/tmp/p.f90:7:3: '+marker+'\n');self.assertTrue(candidate_errors(c,self.src,self.check,r))
 def test_oracle_clean_compile(self):self.assertTrue(oracle_errors(self.case,dict(self.check,err='warning'),self.run))
 def test_oracle_requires_run(self):self.assertTrue(oracle_errors(self.case,self.check,None))
 def test_oracle_compile_only_never_runs(self):
  self.failure();self.assertFalse(oracle_errors(self.case,self.check,None));self.assertTrue(oracle_errors(self.case,self.check,self.run))
 def test_input_binding_validation(self):
  c=dict(name='x',source='cases/x.f90',category='success',gnu='run',inputs=[dict(unit=27,file='inputs/x.txt',bytes=1)])
  validate_cases([c])
  for d in [dict(unit=-1),dict(unit=0),dict(unit=True),dict(file='../secret'),dict(file='/tmp/secret'),dict(bytes=1048577)]:
   x=copy.deepcopy(c);x['inputs'][0].update(d)
   with self.assertRaises(ValueError):validate_cases([x])
 def test_duplicate_binding_rejected(self):
  c=dict(name='x',source='cases/x.f90',category='success',gnu='run',inputs=[dict(unit=27,file='inputs/x.txt',bytes=1)]*2)
  with self.assertRaises(ValueError):validate_cases([c])
 def test_pinned_generator_reproduction(self):
  with tempfile.TemporaryDirectory() as folder:
   d=Path(folder);(d/'cases').mkdir();(d/'inputs').mkdir();shutil.copy2(ROOT/'generate_cases.py',d/'generate_cases.py');r=subprocess.run([sys.executable,str(d/'generate_cases.py')],capture_output=True);self.assertEqual(r.returncode,0,r.stderr)
   self.assertEqual((ROOT/'manifest.json').read_bytes(),(d/'manifest.json').read_bytes())
   for folder in ('cases','inputs'):
    a={p.name:p.read_bytes() for p in (ROOT/folder).iterdir()};b={p.name:p.read_bytes() for p in (d/folder).iterdir()};self.assertEqual(a,b)
if __name__=='__main__':unittest.main()
