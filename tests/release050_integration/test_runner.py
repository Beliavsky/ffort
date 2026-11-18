import unittest,json,tempfile,shutil,subprocess,sys,hashlib
from pathlib import Path
import run_tests as r
class HarnessTests(unittest.TestCase):
 def setUp(self):
  self.src=Path('/tmp/a.f90');self.c=dict(name='x',source='cases/x.f90',category='success',gnu='run',expected_stdout='Ab D e  \n\n')
  self.check=dict(code=0,out='',err='');self.run=dict(code=0,out=self.c['expected_stdout'],err='')
 def test_exact(self):self.assertTrue(r.compare(self.c['expected_stdout'],self.run['out']))
 def test_case(self):self.assertFalse(r.compare('ab\n','Ab\n'))
 def test_d_not_e(self):self.assertFalse(r.compare('D\n','E\n'))
 def test_trailing_blanks(self):self.assertFalse(r.compare('Ab \n','Ab\n'))
 def test_leading_blanks(self):self.assertFalse(r.compare(' Ab\n','Ab\n'))
 def test_tab_not_space(self):self.assertFalse(r.compare('A\tB\n','A B\n'))
 def test_empty_records(self):self.assertFalse(r.compare('A\n\n','A\n'))
 def test_final_newline(self):self.assertFalse(r.compare('A','A\n'))
 def test_crlf(self):self.assertFalse(r.compare('A\r\n','A\n'))
 def test_wide_integer(self):self.assertFalse(r.compare('9007199254740993\n','9007199254740992\n'))
 def test_integer_not_float(self):self.assertFalse(r.compare('32.0\n','32\n'))
 def test_signed_zero(self):self.assertFalse(r.compare('-0\n','0\n'))
 def test_underflow_not_zero(self):self.assertFalse(r.compare('1e-9999\n','0\n'))
 def test_padding_not_normalized(self):self.assertFalse(r.compare(' 32\n','32\n'))
 def test_numeric_relaxation_forbidden(self):
  with self.assertRaises(ValueError):r.compare('1','1',[0])
  with self.assertRaises(ValueError):r.validate_cases([dict(self.c,numeric_lines=[0])])
 def test_clean_check(self):
  for x in [dict(self.check,out=' '),dict(self.check,err=' '),dict(self.check,code=1)]:self.assertTrue(r.candidate_errors(self.c,self.src,x,self.run))
 def test_clean_success(self):
  self.assertFalse(r.candidate_errors(self.c,self.src,self.check,self.run))
  for x in [dict(self.run,err='warning'),dict(self.run,code=2)]:self.assertTrue(r.candidate_errors(self.c,self.src,self.check,x))
 def neg(self,category='runtime'):
  c=dict(self.c,category=category,gnu='compile',expected_stdout='SAFE',diagnostic='unit not supported',diagnostic_line=8,diagnostic_column=3)
  out=dict(code=2,out='SAFE',err='/tmp/a.f90:8:3: unit not supported\n');return c,out
 def test_runtime_exact(self):
  c,x=self.neg();self.assertFalse(r.candidate_errors(c,self.src,self.check,x))
 def test_pending_prefix_atomic(self):
  c,x=self.neg()
  for y in ['','SAFE\n','SAFEx']:self.assertTrue(r.candidate_errors(c,self.src,self.check,dict(x,out=y)))
 def test_exact_negative_diagnostic(self):
  c,x=self.neg()
  for y in ['', 'wrong\n', x['err']+'extra', '/tmp/b.f90:8:3: unit not supported\n','/tmp/a.f90:9:3: unit not supported\n','/tmp/a.f90:8:4: unit not supported\n']:
   self.assertTrue(r.candidate_errors(c,self.src,self.check,dict(x,err=y)))
 def test_negative_status(self):
  c,x=self.neg()
  for n in [0,1,-11,None]:self.assertTrue(r.candidate_errors(c,self.src,self.check,dict(x,code=n)))
 def test_check_reject_both_phases(self):
  c,x=self.neg('reject');c['expected_stdout']='';x.update(code=1,out='')
  self.assertFalse(r.candidate_errors(c,self.src,x,x));self.assertTrue(r.candidate_errors(c,self.src,self.check,x))
 def test_crash_markers(self):
  c,x=self.neg()
  for s in ['Backtrace','Traceback','Fortran runtime error','internal compiler error','SIGSEGV','SIGABRT','AddressSanitizer','TIMEOUT']:
   self.assertTrue(r.candidate_errors(dict(c,diagnostic=s),self.src,self.check,dict(x,err='/tmp/a.f90:8:3: '+s+'\n')))
 def test_compile_only_never_executes(self):
  c,x=self.neg();self.assertFalse(r.oracle_errors(c,self.check,None));self.assertTrue(r.oracle_errors(c,self.check,x))
 def test_oracle_silent(self):
  self.assertTrue(r.oracle_errors(self.c,dict(self.check,err='warning'),self.run))
  self.assertTrue(r.oracle_errors(self.c,self.check,dict(self.run,err='warning')))
 def test_oracle_required(self):self.assertTrue(r.oracle_errors(self.c,self.check,None))
 def test_file_output_detected(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);self.assertFalse(r.input_errors({},p));(p/'fort.99').write_bytes(b'x');self.assertTrue(r.input_errors({},p))
 def test_initial_sources_unchanged(self):
  identity=json.loads((r.ROOT/'oracle-evidence/initial-source-identity.json').read_text())['sources']
  self.assertEqual(len(identity),28)
  for row in identity:
   initial=r.ROOT/'oracle-evidence/initial-attempts'/Path(row['file']).name
   self.assertEqual(r.sha(initial),row['sha256']);self.assertEqual(r.sha(r.ROOT/row['file']),row['sha256'])
 def test_first_oracle_pass_preserved(self):
  first=json.loads((r.ROOT/'oracle-evidence/gnu-first-results.json').read_text())
  self.assertEqual(first['failed'],0);self.assertEqual(first['total'],28);self.assertEqual(first['gnu_executed'],20)
  row=next(x for x in first['records'] if x['name']=='record_defaults_staged_items')
  self.assertEqual(row['oracle']['out'],'[Ab  0F  ]\n')
  current=next(x for x in json.loads((r.ROOT/'manifest.json').read_text())['cases'] if x['name']==row['name'])
  self.assertEqual(current['gnu'],'compile')
 def test_pinned_generator(self):
  r.verify_source_identity(json.loads((r.ROOT/'manifest.json').read_text())['cases'])
  with tempfile.TemporaryDirectory() as d:
   d=Path(d);shutil.copy2(r.ROOT/'generate_cases.py',d/'generate_cases.py')
   x=subprocess.run([sys.executable,str(d/'generate_cases.py')],capture_output=True)
   self.assertEqual(x.returncode,0,x.stderr)
   for f in ['manifest.json','SOURCE-IDENTITY.json']:self.assertEqual((r.ROOT/f).read_bytes(),(d/f).read_bytes())
   for f in ['cases','inputs']:
    self.assertEqual({p.name:p.read_bytes() for p in (r.ROOT/f).glob('*')},{p.name:p.read_bytes() for p in (d/f).glob('*')})
 def test_candidate_identity(self):
  v=dict(code=0,out='fortfront-interpreter 0.50.0; FortFront abc + patches\n',err='')
  self.assertFalse(r.identity_errors('a','a',v,v,'a'))
  self.assertTrue(r.identity_errors('a','b',v,v,'a'))
  self.assertTrue(r.identity_errors('a','a',v,v,'b'))
 def test_version_identity(self):
  v=dict(code=0,out='fortfront-interpreter 0.50.0; FortFront abc + patches\n',err='')
  for x in [dict(v,code=1),dict(v,err='warning'),dict(v,out='0.50.0'),dict(v,out=v['out']+'extra')]:
   self.assertTrue(r.identity_errors('a','a',x,x))
  self.assertTrue(r.identity_errors('a','a',v,dict(v,out=v['out'].replace('0.50.0','0.49.0'))))
 def test_first_candidate_outcomes_preserved(self):
  d=json.loads((r.ROOT/'oracle-evidence/first-candidate-results.json').read_text())
  self.assertEqual(len(d['records']),28);self.assertEqual(d['failed'],1)
  self.assertEqual(d['candidate_sha256'],d['candidate_sha256_after'])
  self.assertEqual(d['candidate_sha256'],'3872c1ea71d75ca9076f35ae7c446d0bc65a9008dbb92b1c48f83a6ac509daa2')
  c=next(c for c in d['records'] if c['name']=='record_defaults_staged_items')
  self.assertEqual(c['category'],'success');self.assertEqual(c['check']['code'],0)
  self.assertEqual(c['ran']['code'],2);self.assertEqual(c['ran']['out'],'');self.assertTrue(c['errors'])
  self.assertTrue(all(not c['errors'] for c in d['records'] if c['name']!='record_defaults_staged_items'))
 def test_undefined_copy_migration_metadata_only(self):
  old=json.loads((r.ROOT/'oracle-evidence/initial-manifest.json').read_text())['cases']
  new=json.loads((r.ROOT/'manifest.json').read_text())['cases'];old={c['name']:c for c in old};new={c['name']:c for c in new}
  self.assertEqual(len(new),30)
  for name,c in old.items():
   self.assertEqual(new[name]['sha256'],c['sha256'])
   if name!='record_defaults_staged_items':
    self.assertEqual(new[name]['gnu'],c['gnu']);self.assertEqual(new[name]['category'],c['category']);self.assertEqual(new[name]['expected_stdout'],c['expected_stdout'])
  c=new['record_defaults_staged_items'];self.assertEqual(c['category'],'runtime');self.assertEqual(c['gnu'],'compile');self.assertEqual(c['expected_stdout'],'')
  self.assertEqual(new['defined_record_copy_staged_items']['category'],'success')
if __name__=='__main__':unittest.main()
