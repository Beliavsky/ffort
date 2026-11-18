#!/usr/bin/env python3
import copy,hashlib,json,shutil,tempfile,unittest
from pathlib import Path
import generate_cases as gen
import run_tests as r

def result(code=0,out='',err=''):
 return dict(returncode=code,stdout=out,stderr=err)
class Contract(unittest.TestCase):
 def setUp(self):
  self.ok=dict(name='ok',mode='run',gnu_mode='execute',stdout='A  \n0 -1 9007199254740993\n')
  self.bad=dict(name='bad',mode='runtime',gnu_mode='compile-only',stdout='SAFE',diagnostic=dict(line=8,column=15,message='vector row index out of bounds'))
  self.src='/exact/path/main.f90'
 def test_version_exact(self):r.validate_version(result(out='fortfront-interpreter 0.52.0; FortFront 9a5896a + documented local patches\n'),'0.52.0')
 def test_version_wrong(self):
  with self.assertRaises(ValueError):r.validate_version(result(out='fortfront-interpreter 0.51.0; FortFront 9a5896a + documented local patches\n'),'0.52.0')
 def test_exact_success(self):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout']))
 def test_text_case(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout'].lower()))
 def test_padding(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout'].replace('A  ','A')))
 def test_record_ending(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout'].replace('\n','\r\n')))
 def test_integer_precision(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout'].replace('993','992')))
 def test_zero_spelling(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout'].replace('0 ','-0 ',1)))
 def test_numeric_tiny_is_not_zero(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout'].replace('0 ','1e-400 ',1)))
 def test_success_stderr(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(),result(out=self.ok['stdout'],err='warning\n'))
 def test_check_must_be_silent(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(out='checked\n'),result(out=self.ok['stdout']))
 def test_check_status(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.ok,self.src,result(1),result(out=self.ok['stdout']))
 def test_runtime_contract(self):r.validate_candidate(self.bad,self.src,result(),result(2,'SAFE',r.diagnostic(self.bad,self.src)))
 def test_runtime_prefix_exact(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.bad,self.src,result(),result(2,'SAFE\n',r.diagnostic(self.bad,self.src)))
 def test_no_partial_output(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.bad,self.src,result(),result(2,'SAFEpartial',r.diagnostic(self.bad,self.src)))
 def test_named_diagnostic(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.bad,self.src,result(),result(2,'SAFE','some error\n'))
 def test_diagnostic_location(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.bad,self.src,result(),result(2,'SAFE',r.diagnostic(self.bad,self.src).replace(':8:15:',':8:16:')))
 def test_diagnostic_path(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.bad,self.src,result(),result(2,'SAFE',r.diagnostic(self.bad,'other.f90')))
 def test_wrong_error_stage(self):
  with self.assertRaises(ValueError):r.validate_candidate(self.bad,self.src,result(1,'',r.diagnostic(self.bad,self.src)),result(1,'',r.diagnostic(self.bad,self.src)))
 def test_rejection_empty_stdout(self):
  c=copy.deepcopy(self.bad);c.update(mode='reject',stdout='');err=r.diagnostic(c,self.src)
  r.validate_candidate(c,self.src,result(1,'',err),result(1,'',err))
  with self.assertRaises(ValueError):r.validate_candidate(c,self.src,result(1,'',err),result(1,'SAFE',err))
 def test_signal(self):
  with self.assertRaises(ValueError):r.clean_result(result(-11))
 def test_crash_markers(self):
  for marker in r.CRASH:
   with self.subTest(marker=marker),self.assertRaises(ValueError):r.clean_result(result(1,err=marker))
 def test_compile_only_not_executed(self):
  r.validate_gnu(self.bad,result())
  with self.assertRaises(ValueError):r.validate_gnu(self.bad,result(),result())
 def test_gnu_requires_clean_compile(self):
  with self.assertRaises(ValueError):r.validate_gnu(self.ok,result(err='warning\n'),result(out=self.ok['stdout']))
 def test_gnu_requires_execution(self):
  with self.assertRaises(ValueError):r.validate_gnu(self.ok,result())
 def test_gnu_crash_not_rejection(self):
  c=dict(gnu_mode='reject',gnu_diagnostic='bad')
  with self.assertRaises(ValueError):r.validate_gnu(c,result(1,err='internal compiler error: bad'))
 def test_source_hash_controls(self):
  with tempfile.TemporaryDirectory() as td:
   gen.generate(td);p=Path(td)/'cases/while_rotation_refresh.f90';p.write_bytes(p.read_bytes()+b'\n')
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_source_inventory(self):
  with tempfile.TemporaryDirectory() as td:
   gen.generate(td);(Path(td)/'cases/extra.f90').write_text('end\n')
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_manifest_duplicate(self):
  with tempfile.TemporaryDirectory() as td:
   gen.generate(td);p=Path(td)/'manifest.json';a=json.loads(p.read_text());a.append(a[0]);p.write_text(json.dumps(a))
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_manifest_bad_mode(self):
  with tempfile.TemporaryDirectory() as td:
   gen.generate(td);p=Path(td)/'manifest.json';a=json.loads(p.read_text());a[0]['gnu_mode']='skip';p.write_text(json.dumps(a))
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_reproducible_generator(self):
  with tempfile.TemporaryDirectory() as td:
   gen.generate(td)
   paths=['manifest.json']+[str(x.relative_to(r.ROOT))for x in sorted((r.ROOT/'cases').glob('*.f90'))]
   for p in paths:
    with self.subTest(path=p):self.assertEqual((Path(td)/p).read_bytes(),(r.ROOT/p).read_bytes())
 def test_first_sources_unchanged(self):
  proof=json.loads((r.ROOT/'provenance.json').read_text())
  for name,h in proof['first18_sources'].items():self.assertEqual(r.digest(r.ROOT/'cases'/(name+'.f90')),h)
if __name__=='__main__':unittest.main()
