import unittest,tempfile,subprocess,json,sys,io,contextlib
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
import run_strict as r
class Tests(unittest.TestCase):
 def result(self,status=0,out=b'',err=b''):return dict(status=status,stdout_hex=out.hex(),stderr_hex=err.hex())
 def test_exact_contract(self):r.contract(self.result(2,b'',b'x:2:1: error\n'),2,b'',b'x:2:1: error\n')
 def test_false_status_not_zero(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(False),0,b'',b'')
 def test_true_status_not_one(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(True),1,b'',b'')
 def test_negative_status(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(-1),-1,b'',b'')
 def test_existing_report_preserved(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'report.json';p.write_bytes(b'preserve first evidence')
   args=['runner']
   for name in ['candidate','gfortran','compiler-binary','runtime-source']:args+=['--'+name,str(Path(d)/name)]
   args+=['--result',str(p)]
   for name in ['candidate-sha256','compiler-sha256','compiler-binary-sha256','runtime-sha256','manifest-sha256']:args+=['--'+name,'0'*64]
   with patch.object(sys,'argv',args),patch.object(r,'invoke') as call,contextlib.redirect_stdout(io.StringIO()):
    self.assertEqual(r.main(),1)
   call.assert_not_called();self.assertEqual(p.read_bytes(),b'preserve first evidence')
 def test_wrong_status(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(0),2,b'',b'')
 def test_extra_stdout(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(1,b'noise'),1,b'',b'')
 def test_missing_stderr(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(1),1,b'',b'error\n')
 def test_wrong_location(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(1,b'',b'x:3:2: error\n'),1,b'',b'x:2:1: error\n')
 def test_extra_warning(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(0,b'ok\n',b'warning\n'),0,b'ok\n',b'')
 def test_spacing_not_normalized(self):
  with self.assertRaises(r.ContractError):r.contract(self.result(0,b' 1\n'),0,b'1\n',b'')
 def test_path_escape(self):
  with self.assertRaises(r.ContractError):r.owned('../outside')
 def test_bad_hash_syntax(self):
  with self.assertRaises(r.ContractError):r.verify(__file__,'notasha')
 def test_hash_mismatch(self):
  with self.assertRaises(r.ContractError):r.verify(__file__,'0'*64)
 def test_timeout(self):
  with patch.object(r.subprocess,'run',side_effect=subprocess.TimeoutExpired('fake',20)):
   with self.assertRaises(r.ContractError):r.invoke(['fake'],'.',[])
 def test_after_hash_mutation(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'p';p.write_bytes(b'before');h=r.digest(p)
   def mutate(*args,**kwargs):p.write_bytes(b'after');return SimpleNamespace(returncode=0,stdout=b'',stderr=b'')
   with patch.object(r.subprocess,'run',side_effect=mutate):
    with self.assertRaises(r.ContractError):r.invoke(['fake'],d,[(p,h)])
 def row(self,stage):return next(x for x in json.loads((r.ROOT/'manifest.json').read_text()) if x['stage']==stage)
 def test_success_all_four_stages(self):
  row=self.row('success');out=r.owned(row['stdout']).read_bytes()
  with patch.object(r,'invoke',side_effect=[self.result(),self.result(0,out),self.result(),self.result(0,out)]):
   got=r.run_case(row,SimpleNamespace(candidate='candidate',gfortran='compiler'),'/tmp',[])
  self.assertTrue(got['passed']);self.assertEqual(len(got['operations']),4)
 def test_check_failure_blocks_execution(self):
  with patch.object(r,'invoke',return_value=self.result(1)) as mock:
   got=r.run_case(self.row('success'),SimpleNamespace(candidate='candidate',gfortran='compiler'),'/tmp',[])
  self.assertFalse(got['passed']);self.assertEqual(mock.call_count,1)
 def test_static_exact_diagnostic(self):
  row=self.row('static');err=row['stderr'].replace('@SOURCE@',str(r.owned(row['source']))).encode()
  with patch.object(r,'invoke',side_effect=[self.result(1,b'',err),self.result(1,b'',err)]):
   got=r.run_case(row,SimpleNamespace(candidate='candidate',gfortran='compiler'),'/tmp',[])
  self.assertTrue(got['passed'])
 def test_runtime_needs_successful_check(self):
  row=self.row('runtime');err=row['stderr'].replace('@SOURCE@',str(r.owned(row['source']))).encode()
  with patch.object(r,'invoke',side_effect=[self.result(),self.result(2,b'',err)]):
   got=r.run_case(row,SimpleNamespace(candidate='candidate',gfortran='compiler'),'/tmp',[])
  self.assertTrue(got['passed'])
 def test_compiler_warning_fails(self):
  row=self.row('success');out=r.owned(row['stdout']).read_bytes()
  with patch.object(r,'invoke',side_effect=[self.result(),self.result(0,out),self.result(0,b'',b'warning')]):
   got=r.run_case(row,SimpleNamespace(candidate='candidate',gfortran='compiler'),'/tmp',[])
  self.assertFalse(got['passed'])
 def test_oracle_disagreement_fails(self):
  row=self.row('success');out=r.owned(row['stdout']).read_bytes()
  with patch.object(r,'invoke',side_effect=[self.result(),self.result(0,out),self.result(),self.result(0,b'wrong')]):
   got=r.run_case(row,SimpleNamespace(candidate='candidate',gfortran='compiler'),'/tmp',[])
  self.assertFalse(got['passed'])
if __name__=='__main__':unittest.main()
