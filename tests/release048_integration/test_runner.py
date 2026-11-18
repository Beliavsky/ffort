import unittest,json,copy,tempfile,shutil,subprocess,sys,hashlib
from unittest.mock import patch
import run_tests as runner
from pathlib import Path
from run_tests import compare,candidate_errors,oracle_errors,validate_cases,verify_source_identity,ROOT
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
 def test_known_gnu_rejection_is_not_successful_execution(self):
  c=dict(self.case,gnu='known-reject',gnu_compile_diagnostic='same length')
  rejected=dict(code=1,out='',err='GNU requires same length operands')
  self.assertFalse(oracle_errors(c,rejected,None))
  self.assertTrue(oracle_errors(c,self.check,self.run))
  self.assertTrue(oracle_errors(c,rejected,self.run))
 def test_known_gnu_rejection_still_rejects_ice(self):
  c=dict(self.case,gnu='known-reject',gnu_compile_diagnostic='same length')
  for code,err in [(1,'internal compiler error: same length'),(4,'same length'),(1,'unrelated compiler error')]:self.assertTrue(oracle_errors(c,dict(code=code,out='',err=err),None))
 def test_independent_character_oracle_stays_exact(self):
  c=dict(self.case,expected_stdout='[YY][A ]\n',gnu='known-reject')
  self.assertFalse(candidate_errors(c,self.src,self.check,dict(code=0,out='[YY][A ]\n',err='')))
  self.assertTrue(candidate_errors(c,self.src,self.check,dict(code=0,out='[Y][A]\n',err='')))
 def test_no_numeric_relaxation_in_composition_manifest(self):
  c=dict(name='x',source='cases/x.f90',category='success',gnu='run',numeric_lines=[0])
  with self.assertRaises(ValueError):validate_cases([c])
 def test_exact_bit_padding_and_case(self):
  expected='[00FF  ]\n'
  for actual in ['[00ff  ]\n','[FF  ]\n','[00FF]\n','[00FF  ]\r\n','[00FE  ]\n']:
   self.assertFalse(compare(actual,expected))
 def test_machine_boundary_never_float_coerced(self):
  self.assertFalse(compare('8000000000000001\n','8000000000000000\n'))
 def test_initial_attempt_evidence_pinned(self):
  evidence=ROOT/'oracle-evidence'
  original=json.loads((evidence/'initial-source-identity.json').read_text())['sources']
  for item in original:
   path=evidence/'initial-attempts'/Path(item['file']).name
   self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),item['sha256'])
 def test_prepreview_sources_not_rewritten(self):
  identity=json.loads((ROOT/'oracle-evidence/prepreview-source-identity.json').read_text())['sources']
  self.assertEqual(len(identity),27)
  for item in identity:self.assertEqual(hashlib.sha256((ROOT/item['file']).read_bytes()).hexdigest(),item['sha256'])
 def test_attempt_lineage_preserves_all_first_bytes(self):
  evidence=ROOT/'oracle-evidence'
  for row in json.loads((evidence/'attempt-lineage.json').read_text())['rows']:
   first=evidence/'initial-attempts'/(row['name']+'.f90')
   self.assertEqual(hashlib.sha256(first.read_bytes()).hexdigest(),row['initial_sha256'])
   current=ROOT/'cases'/(row['name']+'.f90')
   self.assertEqual(hashlib.sha256(current.read_bytes()).hexdigest(),row['maintained_sha256'])
 def test_pinned_generator_reproduction(self):
  verify_source_identity(json.loads((ROOT/'manifest.json').read_text())['cases'])
  with tempfile.TemporaryDirectory() as folder:
   d=Path(folder);(d/'cases').mkdir();(d/'inputs').mkdir();shutil.copy2(ROOT/'generate_cases.py',d/'generate_cases.py');r=subprocess.run([sys.executable,str(d/'generate_cases.py')],capture_output=True);self.assertEqual(r.returncode,0,r.stderr)
   self.assertEqual((ROOT/'manifest.json').read_bytes(),(d/'manifest.json').read_bytes())
   self.assertEqual((ROOT/'SOURCE-IDENTITY.json').read_bytes(),(d/'SOURCE-IDENTITY.json').read_bytes())
   for folder in ('cases','inputs'):
    a={p.name:p.read_bytes() for p in (ROOT/folder).glob('*')};b={p.name:p.read_bytes() for p in (d/folder).glob('*')};self.assertEqual(a,b)
class InputIsolationTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name);(self.root/'inputs').mkdir();(self.root/'work').mkdir()
  self.data=b"'Ab  ' 12\n";self.fixture=self.root/'inputs'/'x.dat';self.fixture.write_bytes(self.data)
  self.case=dict(inputs=[dict(unit=27,file='inputs/x.dat',bytes=len(self.data),sha256=hashlib.sha256(self.data).hexdigest())])
 def tearDown(self):self.temp.cleanup()
 def prepare(self):
  with patch.object(runner,'ROOT',self.root):return runner.prepare_inputs(self.case,self.root/'work')
 def test_distinct_explicit_inputs(self):
  g,c,b,i=self.prepare();self.assertEqual((g/'fort.27').read_bytes(),self.data);self.assertEqual((c/'input_27.dat').read_bytes(),self.data)
  self.assertFalse((c/'fort.27').exists());self.assertEqual(b,['--input','27='+str(c/'input_27.dat')]);self.assertFalse(runner.input_errors(i,c))
 def test_candidate_cannot_mutate_oracle_copy(self):
  g,c,b,i=self.prepare();(c/'input_27.dat').write_bytes(b'changed');self.assertEqual((g/'fort.27').read_bytes(),self.data);self.assertTrue(runner.input_errors(i,c))
 def test_oracle_mutation_detected(self):
  g,c,b,i=self.prepare();(g/'fort.27').write_bytes(b'changed');self.assertTrue(runner.input_errors(i,c))
 def test_missing_bound_input_detected(self):
  g,c,b,i=self.prepare();(c/'input_27.dat').unlink();self.assertTrue(runner.input_errors(i,c))
 def test_implicit_native_file_detected(self):
  g,c,b,i=self.prepare();(c/'fort.27').write_bytes(self.data);self.assertTrue(runner.input_errors(i,c))
 def test_pinned_input_corruption_rejected(self):
  self.fixture.write_bytes(b'different')
  with self.assertRaises(ValueError):self.prepare()
 def test_empty_inputs_need_no_fixture_directory(self):
  with patch.object(runner,'ROOT',self.root/'absent'):
   g,c,b,i=runner.prepare_inputs({},self.root/'work')
  self.assertEqual(b,[]);self.assertFalse(runner.input_errors(i,c))
 def test_missing_nonempty_fixture_not_treated_empty(self):
  self.fixture.unlink()
  with self.assertRaises(FileNotFoundError):self.prepare()
if __name__=='__main__':unittest.main()
