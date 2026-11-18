"""Structural fail-closed tests. Mutation artifacts deliberately retained."""
import copy,hashlib,json,tempfile,unittest
from pathlib import Path
import run_tests as r
record=r.process_record
class StructuralContract(unittest.TestCase):
 def suite(self):
  root=Path(tempfile.mkdtemp(prefix='numeric-vector-contract-'));(root/'cases').mkdir()
  source=root/'cases/control.f90';source.write_text('program p\nend program\n')
  row=dict(name='control',source='cases/control.f90',sha256=r.sha(source),stage='success',gnu='run',expected='',diagnostic=None,gnu_stderr='',gnu_expected='')
  (root/'manifest.json').write_text(json.dumps({'cases':[row]}));return root,row
 def write(self,root,rows): (root/'manifest.json').write_text(json.dumps({'cases':rows}))
 def test_process_schema(self):
  success=record(code=0,out='',err='');case=dict(stage='success',expected='',diagnostic=None,gnu='run',gnu_stderr='',gnu_expected='')
  bad=[None,[],{},record(code=False,out='',err=''),record(code=0.0,out='',err=''),record(code='0',out='',err=''),dict(success,out=b''),dict(success,err=None),dict(success,ignored='unexpected')]
  for value in bad:
   with self.subTest(value=value):
    self.assertTrue(r.candidate_errors(case,Path('p'),value,success))
    self.assertTrue(r.candidate_errors(case,Path('p'),success,value))
    self.assertTrue(r.gnu_errors(case,Path('p'),value,success))
    self.assertTrue(r.gnu_errors(case,Path('p'),success,value))
  self.assertTrue(r.candidate_errors(case,Path('p'),dict(success,code=None),success))
 def test_case_bijection(self):
  root,row=self.suite();self.assertEqual(len(r.load_cases(root)),1)
  for rows in ([row,row],[row,dict(row,name='other')],[dict(row,source='other.f90')],[dict(row,source='../control.f90')],[dict(row,name='../../escape')]):
   self.write(root,rows)
   with self.assertRaises(ValueError):r.load_cases(root)
  self.write(root,[row]);(root/'cases/extra.f90').write_text('end\n')
  with self.assertRaises(ValueError):r.load_cases(root)
 def test_schema_mode_hash_guards(self):
  root,row=self.suite()
  mutations=[dict(row,sha256='0'*64),dict(row,sha256=3),dict(row,stage='pending'),dict(row,gnu='invalid'),dict(row,expected=0),dict(row,gnu_stderr=None),dict(row,gnu_expected=[]),dict(row,diagnostic=17),dict(row,diagnostic='1:1: stale'),dict(row,extra=True),dict(row,gnu_flags='-bad')]
  missing=dict(row);del missing['gnu_stderr'];mutations.append(missing)
  for changed in mutations:
   with self.subTest(changed=changed):
    self.write(root,[changed])
    with self.assertRaises(ValueError):r.load_cases(root)
 def test_source_hash_and_symlink_guards(self):
  root,row=self.suite();(root/'cases/control.f90').write_text('print *,42\nend\n')
  with self.assertRaises(ValueError):r.load_cases(root)
  root,row=self.suite();source=root/'cases/control.f90';saved=root/'saved-original.f90';source.rename(saved);source.symlink_to(saved)
  with self.assertRaises(ValueError):r.load_cases(root)
 def test_duplicate_json_keys(self):
  root,row=self.suite();(root/'manifest.json').write_text('{"cases":[],"cases":[]}')
  with self.assertRaises(ValueError):r.load_cases(root)
 def test_version_checks(self):
  out='fortfront-interpreter 0.53.0; FortFront 9a5896a + documented local patches\n';good=record(code=0,out=out,err='')
  self.assertEqual(r.version_errors(good,'0.53.0'),[])
  for bad in [dict(good,code=False),dict(good,code=1),dict(good,err='\n'),dict(good,out=out+'\n'),dict(good,out=out.replace('0.53.0','0.52.0')),dict(good,out='0.53.0\n')]:
   with self.subTest(bad=bad):self.assertTrue(r.version_errors(bad,'0.53.0'))
 def test_manifest_and_provenance_on_real_sources(self):
  self.assertEqual(len(r.load_cases()),98);self.assertTrue(r.check_provenance())
 def test_provenance_hash_failure(self):
  import shutil
  root=Path(tempfile.mkdtemp(prefix='numeric-vector-provenance-'));(root/'source').mkdir();(root/'cases').mkdir()
  shutil.copyfile(r.R/'source/exact_closure.f90',root/'source/exact_closure.f90');shutil.copyfile(r.R/'source/dependency_closure.f90',root/'source/dependency_closure.f90')
  meta=r.read_json(r.R/'provenance.json');meta['bodies'][0]['sha256']='0'*64;(root/'provenance.json').write_text(json.dumps(meta))
  with self.assertRaises(ValueError):r.check_provenance(root)
 def test_invalid_utf8_and_raw_integrity(self):
  valid=record(0,b'1\n',b'');self.assertTrue(r.valid_process(valid))
  invalid=record(0,b'\xff1\n',b'');self.assertFalse(invalid['utf8']);self.assertFalse(r.valid_process(invalid))
  self.assertEqual(invalid['stdout_b64'],'/zEK')
  for key,value in [('stdout_sha256','0'*64),('stdout_b64','!bad'),('out','2\n'),('utf8',1)]:
   with self.subTest(key=key):self.assertFalse(r.valid_process(dict(valid,**{key:value})))
 def test_timeout_and_spawn_failures_preserve_partial_streams(self):
  from unittest.mock import patch
  import subprocess
  with patch.object(r.subprocess,'run',side_effect=subprocess.TimeoutExpired('probe',1,output=b'partial\xff',stderr=b'error')):
   row=r.run(['probe'],Path('.'))
  self.assertEqual(row['termination'],'timeout');self.assertIsNone(row['code']);self.assertEqual(row['stdout_b64'],'cGFydGlhbP8=');self.assertEqual(row['err'],'error');self.assertFalse(r.valid_process(row))
  with patch.object(r.subprocess,'run',side_effect=FileNotFoundError('missing probe')):
   row=r.run(['probe'],Path('.'))
  self.assertEqual(row['termination'],'spawn-error');self.assertIn('missing probe',row['error']);self.assertFalse(r.valid_process(row))
 def test_candidate_crash_never_valid_negative(self):
  path=Path('probe.f90')
  for marker in ('SIGSEGV','Backtrace','Fortran runtime error','Internal compiler error','TIMEOUT'):
   case=dict(stage='compile',expected='',diagnostic='7:12: '+marker)
   row=record(1,'','probe.f90:7:12: '+marker+'\n')
   self.assertTrue(r.candidate_errors(case,path,row,row))
 def test_new_output_paths_only(self):
  root=Path(tempfile.mkdtemp(prefix='numeric-output-guards-'));fresh=root/'fresh.json'
  self.assertEqual(r.require_new_path(fresh),fresh.absolute());fresh.write_text('preserve')
  with self.assertRaises(ValueError):r.require_new_path(fresh)
  link=root/'linked';link.symlink_to(root,target_is_directory=True)
  with self.assertRaises(ValueError):r.require_new_path(link/'new.json')
  with self.assertRaises(ValueError):r.require_new_path(root/'missing/new.json')
  self.assertEqual(fresh.read_text(),'preserve')
 def test_suite_identity_includes_policies_and_sources(self):
  root=Path(tempfile.mkdtemp(prefix='numeric-policy-identity-'));(root/'source').mkdir();(root/'cases').mkdir()
  for name in ('manifest.json','contracts.json','provenance.json','source/exact_closure.f90','source/dependency_closure.f90','cases/control.f90','run_tests.py'):(root/name).write_text('initial')
  first=r.suite_identity(root);self.assertEqual(len(first),7)
  for name in first:
   file=root/name;previous=file.read_text();file.write_text(previous+'changed');self.assertNotEqual(r.suite_identity(root),first);file.write_text(previous)
 def test_explicit_budget_policy(self):
  root,row=self.suite()
  for value in (False,0,-1,100000001,'100000000',1.5):
   self.write(root,[dict(row,max_steps=value)])
   with self.assertRaises(ValueError):r.load_cases(root)
  self.write(root,[dict(row,max_steps=100000000)])
  self.assertEqual(r.load_cases(root)[0]['max_steps'],100000000)
if __name__=='__main__':unittest.main()
