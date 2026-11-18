import unittest, pathlib, tempfile, shutil, subprocess, sys, json, hashlib
from strict_contract import compare_stdout,diagnostic,check_record
class Contracts(unittest.TestCase):
 def test_text_exact(self):self.assertFalse(compare_stdout('parameter','ef \nab\n','ef\nab\n'))
 def test_numeric_padding(self):self.assertTrue(compare_stdout('empty',' 0\n','           0\n'))
 def test_numeric_wrong(self):self.assertFalse(compare_stdout('empty','1\n','0\n'))
 def test_numeric_line_boundary(self):self.assertFalse(compare_stdout('zero_length','3\n0\n','3 0\n'))
 def test_numeric_not_numeric(self):self.assertFalse(compare_stdout('empty','nan\n','0\n'))
 def test_diag_exact(self):self.assertTrue(diagnostic({'status':2,'stdout':'','stderr':'a.f90:3:2: bad\n'},'a.f90',2,3,2,'bad'))
 def test_diag_wrong_status(self):self.assertFalse(diagnostic({'status':1,'stdout':'','stderr':'a.f90:3:2: bad\n'},'a.f90',2,3,2,'bad'))
 def test_diag_wrong_path(self):self.assertFalse(diagnostic({'status':2,'stdout':'','stderr':'b.f90:3:2: bad\n'},'a.f90',2,3,2,'bad'))
 def test_diag_wrong_column(self):self.assertFalse(diagnostic({'status':2,'stdout':'','stderr':'a.f90:3:1: bad\n'},'a.f90',2,3,2,'bad'))
 def test_diag_noise(self):self.assertFalse(diagnostic({'status':2,'stdout':'','stderr':'a.f90:3:2: bad\nextra\n'},'a.f90',2,3,2,'bad'))
 def test_stdout_on_failure(self):self.assertFalse(diagnostic({'status':2,'stdout':'oops','stderr':'a.f90:3:2: bad\n'},'a.f90',2,3,2,'bad'))
 def test_wrong_phase(self):self.assertTrue(check_record({'name':'empty','check':{'status':1,'stdout':'','stderr':'a.f90:3:2: bad\n'}},{'phase':'runtime','diagnostic':{'status':2,'line':3,'column':2,'message':'bad'}},'a.f90'))
 def test_generator_replay(self):
  root=pathlib.Path(__file__).resolve().parent.parent
  with tempfile.TemporaryDirectory()as d:
   target=pathlib.Path(d);shutil.copy2(root/'make_cases.py',target/'make_cases.py')
   for p in root.glob('utilities-*-original-body.f90'):shutil.copy2(p,target/p.name)
   subprocess.run([sys.executable,str(target/'make_cases.py')],check=True,capture_output=True)
   for p in (root/'tests/cases').glob('*.f90'):self.assertEqual(p.read_bytes(),(target/'tests/cases'/p.name).read_bytes())
   self.assertEqual((root/'tests/manifest.json').read_bytes(),(target/'tests/manifest.json').read_bytes())
 def test_source_hashes(self):
  root=pathlib.Path(__file__).resolve().parent
  for c in json.loads((root/'manifest.json').read_text())['cases']:
   self.assertEqual(c['sha256'],hashlib.sha256((root/c['source']).read_bytes()).hexdigest())
 def test_complete_expectations(self):
  root=pathlib.Path(__file__).resolve().parent
  self.assertEqual(set(json.loads((root/'expectations.json').read_text())),{c['name']for c in json.loads((root/'manifest.json').read_text())['cases']})
 def test_runtime_stdout_not_accepted(self):
  x={'name':'empty','check':{'status':0,'stdout':'','stderr':''},'candidate_run':{'status':2,'stdout':'0\n','stderr':'a.f90:3:2: bad\n'}}
  self.assertTrue(check_record(x,{'phase':'runtime','diagnostic':{'status':2,'line':3,'column':2,'message':'bad'}},'a.f90'))
if __name__=='__main__':unittest.main()
