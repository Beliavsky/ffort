import unittest,tempfile,sys,io,contextlib,json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
import run_tests as r
class Tests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);(self.root/'src').mkdir();(self.root/'src/fi_runtime.f90').write_text('source')
  self.exe=self.root/'candidate';self.exe.write_text('candidate');self.compiler=self.root/'gfortran';self.compiler.write_text('compiler');self.result=self.root/'receipt.json'
  self.args=['run_tests','--candidate',str(self.exe),'--gfortran',str(self.compiler),'--expected-version','0.54.0','--result',str(self.result)]
  self.banner=SimpleNamespace(returncode=0,stdout=b'fortfront-interpreter 0.54.0; FortFront 9a5896a + documented local patches\n',stderr=b'')
 def tearDown(self):self.tmp.cleanup()
 def invoke(self,side):
  with patch.object(sys,'argv',self.args),patch.object(r,'PROJECT',self.root),patch.object(r.subprocess,'run',side_effect=side) as m,contextlib.redirect_stdout(io.StringIO()):return r.main(),m
 def test_pin_and_forward(self):
  status,m=self.invoke([self.banner,SimpleNamespace(returncode=0)])
  self.assertEqual(status,0);cmd=m.call_args_list[1].args[0]
  self.assertIn('--manifest-sha256',cmd);self.assertIn(r.MANIFEST_SHA,cmd);self.assertIn('--runtime-sha256',cmd)
  receipt=json.loads(self.result.with_suffix('.invocation.json').read_text());self.assertFalse(receipt['underlying_compiler_explicit']);self.assertEqual(receipt['expected_version'],'0.54.0')
 def test_failure_propagated(self):
  status,_=self.invoke([self.banner,SimpleNamespace(returncode=1)]);self.assertEqual(status,1)
 def test_bad_version(self):
  self.banner.stdout=b'wrong\n'
  with self.assertRaises(SystemExit):self.invoke([self.banner])
  self.assertTrue(self.result.with_suffix('.invocation.json').exists())
 def test_version_stderr(self):
  self.banner.stderr=b'warning\n'
  with self.assertRaises(SystemExit):self.invoke([self.banner])
 def test_version_exit(self):
  self.banner.returncode=1
  with self.assertRaises(SystemExit):self.invoke([self.banner])
 def test_existing_result(self):
  self.result.write_text('preserve')
  with self.assertRaises(SystemExit):self.invoke([])
  self.assertEqual(self.result.read_text(),'preserve')
 def test_input_result_refused(self):
  self.args[-1]=str(self.exe)
  with self.assertRaises(SystemExit):self.invoke([])
  self.assertEqual(self.exe.read_text(),'candidate')
 def test_existing_invocation_preserved(self):
  self.result.with_suffix('.invocation.json').write_text('preserve')
  with self.assertRaises(FileExistsError):self.invoke([self.banner])
  self.assertEqual(self.result.with_suffix('.invocation.json').read_text(),'preserve')
 def test_mutation_during_version(self):
  def mutate(*a,**k):self.exe.write_text('changed');return self.banner
  with self.assertRaises(SystemExit):self.invoke(mutate)
if __name__=='__main__':unittest.main()
