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
 def test_version_exact(self):r.validate_version(result(out='fortfront-interpreter 0.54.0; FortFront 9a5896a + documented local patches\n'),'0.54.0')
 def test_version_wrong(self):
  with self.assertRaises(ValueError):r.validate_version(result(out='fortfront-interpreter 0.53.0; FortFront 9a5896a + documented local patches\n'),'0.54.0')
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
   gen.generate(td);p=Path(td)/'cases/while_unit_refresh.f90';p.write_bytes(p.read_bytes()+b'\n')
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
   paths=['manifest.json','input-manifest.json','inputs/alpha input.dat','inputs/beta.dat']+[str(x.relative_to(r.ROOT))for x in sorted((r.ROOT/'cases').glob('*.f90'))]
   for p in paths:
    with self.subTest(path=p):self.assertEqual((Path(td)/p).read_bytes(),(r.ROOT/p).read_bytes())
 def test_first_sources_unchanged(self):
  proof=json.loads((r.ROOT/'provenance.json').read_text())
  for name,h in proof['first12_sources'].items():self.assertEqual(r.digest(r.ROOT/'cases'/(name+'.f90')),h)
 def test_input_source_hash(self):
  with tempfile.TemporaryDirectory()as td:
   gen.generate(td);p=Path(td)/'inputs/beta.dat';p.write_bytes(b'9\n')
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_missing_nonempty_inputs(self):
  with tempfile.TemporaryDirectory()as td:
   gen.generate(td);(Path(td)/'inputs/beta.dat').unlink()
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_extra_input_rejected(self):
  with tempfile.TemporaryDirectory()as td:
   gen.generate(td);(Path(td)/'inputs/extra.dat').write_text('x')
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_duplicate_input_units(self):
  with tempfile.TemporaryDirectory()as td:
   gen.generate(td);p=Path(td)/'input-manifest.json';a=json.loads(p.read_text());a['beta.dat']['unit']=17;p.write_text(json.dumps(a))
   with self.assertRaises(ValueError):r.load_inputs(Path(td))
 def test_input_mutation_detected(self):
  with tempfile.TemporaryDirectory()as td:
   r.stage_inputs(Path(td));(Path(td)/'alpha input.dat').write_bytes(b'changed')
   with self.assertRaises(ValueError):r.check_inputs(Path(td))
 def test_oracle_only_marker_changes(self):
  raw=b"iu=17\n! GNU_REGISTER_INPUT\ninquire(unit=iu,name=nm)\n"
  wrapped=r.gnu_source(raw,r.load_inputs())
  self.assertTrue(wrapped.startswith(b'iu=17\nopen(unit=17,'));self.assertTrue(wrapped.endswith(b'inquire(unit=iu,name=nm)\n'))
  self.assertEqual(wrapped.count(b'open('),2)
 def test_oracle_multiple_markers_rejected(self):
  with self.assertRaises(ValueError):r.gnu_source(b'! GNU_REGISTER_INPUT\n! GNU_REGISTER_INPUT',r.load_inputs())
 def test_timeout_rejected(self):
  a=result();a['timeout']=True
  with self.assertRaises(ValueError):r.clean_result(a)
 def test_boolean_exit_rejected(self):
  with self.assertRaises(ValueError):r.clean_result(result(False))
 def test_crash_in_stdout_rejected(self):
  with self.assertRaises(ValueError):r.clean_result(result(out='SIGSEGV'))
 def test_non_string_stream_rejected(self):
  with self.assertRaises(ValueError):r.clean_result(result(out=b'A'))
 def test_corrupt_unicode_rejected(self):
  with self.assertRaises(ValueError):r.clean_result(result(out='\ufffd'))
 def test_gnu_rejection_location(self):
  c=dict(gnu_mode='reject',gnu_diagnostic='expected error')
  with self.assertRaises(ValueError):r.validate_gnu(c,result(1,err='expected error'))
 def test_unpinned_negative_cannot_pass_candidate(self):
  c=copy.deepcopy(self.bad);c['diagnostic']=None
  with self.assertRaises(ValueError):r.validate_candidate(c,self.src,result(),result(2,'SAFE','some error\n'))
 def test_unpinned_reject_cannot_hide_output(self):
  with tempfile.TemporaryDirectory() as td:
   gen.generate(td);p=Path(td)/'manifest.json';a=json.loads(p.read_text());a[0].update(mode='reject',stdout='BAD',diagnostic=None);p.write_text(json.dumps(a))
   with self.assertRaises(ValueError):r.load_manifest(Path(td))
 def test_all18_original_source_hashes(self):
  proof=json.loads((r.ROOT/'provenance.json').read_text())
  self.assertEqual(len(proof['first18_sources']),18)
  for name,h in proof['first18_sources'].items():self.assertEqual(r.digest(r.ROOT/'cases'/(name+'.f90')),h)
 def test_first12_contracts_unchanged(self):
  proof=json.loads((r.ROOT/'provenance.json').read_text())
  self.assertEqual(r.load_manifest()[:12],proof['first12_contracts'])
 def test_alias_wrong_diagnostic_rejected(self):
  c=next(x for x in r.load_manifest()if x['name']=='substring_bare_samebase_boundary')
  with self.assertRaises(ValueError):r.validate_candidate(c,self.src,result(),result(2,'KEEP',self.src+':17:1: different boundary\n'))
 def test_short_record_missing_prior_prefix_rejected(self):
  c=next(x for x in r.load_manifest()if x['name']=='short_fzero_after_substring_atomic_output')
  with self.assertRaises(ValueError):r.validate_candidate(c,self.src,result(),result(2,'KEEP',r.diagnostic(c,self.src)))
 def test_fzero_padding_not_normalized(self):
  c=next(x for x in r.load_manifest()if x['name']=='fzero_element_substring_records')
  with self.assertRaises(ValueError):r.validate_candidate(c,self.src,result(),result(0,'[-9.25]|[2.5]\n',''))
if __name__=='__main__':unittest.main()
