import shutil,base64,copy,hashlib,json,pathlib,subprocess,sys,tempfile,unittest,os
from unittest.mock import patch
from process_contract import capture,reserve_output
from validate_results import stage_errors,validate,inventory,VERSION
ROOT=pathlib.Path(__file__).resolve().parent
M=json.loads((ROOT/'manifest.json').read_text());G=json.loads((ROOT/'gnu-profile.json').read_text());C='a'*64

def stage(argv,cwd,status=0,stdout='',stderr=''):
 s=dict(argv=argv,cwd=cwd,status=status,stdout=stdout,stderr=stderr,timeout=False,valid_utf8=True,spawn_error=None)
 for k in ['stdout','stderr']:
  raw=s[k].encode();s[k+'_base64']=base64.b64encode(raw).decode();s[k+'_sha256']=hashlib.sha256(raw).hexdigest()
 return s
def fixture():
 exe='/candidate';gnu='/gnu';r={'candidate':exe,'gnu':gnu,'records':[],'inputs_before':inventory(ROOT,M),'inputs_after':inventory(ROOT,M)}
 for when in ['before','after']:
  r['candidate_sha256_'+when]=C;r['gnu_sha256_'+when]=G['sha256'];r['version_'+when]=stage([exe,'--version'],str(ROOT),stdout=VERSION);r['gnu_version_'+when]=stage([gnu,'--version'],str(ROOT),stdout=G['stdout'])
 for c in M:
  src=str(ROOT/c['source']);d='/tmp/test-'+c['name'];row={k:c[k]for k in ['name','source','sha256','gnu_run']};row['cwd']=d
  for phase,args in [('check',['--check']),('run',[])]:row[phase]=stage([exe]+args+[src],d,**{k:v.replace('{source}',src)if type(v)is str else v for k,v in c[phase].items()})
  row['gnu_compile']=stage([gnu,'-std=f2018','-fcheck=all',src,'-o',d+'/oracle'],d)
  row['gnu_execution']=stage([d+'/oracle'],d,stdout=c['gnu_stdout'])if c['gnu_run']else None;r['records'].append(row)
 return r
class Contract(unittest.TestCase):
 def bad(self,fn):r=fixture();fn(r);self.assertTrue(validate(r,M,ROOT,C,G['sha256']))
 def test_supplied_manifest_poison(self):
  changed=copy.deepcopy(M);changed[0]['run']['stdout']='POISON\n';r=fixture();row=r['records'][0];row['run']=stage(row['run']['argv'],row['cwd'],stdout='POISON\n')
  self.assertIn('supplied manifest differs from pinned contract',validate(r,changed,ROOT,C,G['sha256']))
 def test_changed_source_rebound_inventory(self):
  with tempfile.TemporaryDirectory()as d:
   root=pathlib.Path(d);shutil.copytree(ROOT,root,dirs_exist_ok=True,ignore=shutil.ignore_patterns('__pycache__'))
   p=root/M[0]['source'];p.write_bytes(p.read_bytes()+b'! POISON\n')
   r=fixture();r['inputs_before']=inventory(root,M);r['inputs_after']=inventory(root,M)
   errors=validate(r,M,root,C,G['sha256'])
   self.assertTrue(any('fixture bytes differ from pinned source identity' in x for x in errors))
 def test_valid(self):self.assertEqual(validate(fixture(),M,ROOT,C,G['sha256']),[])
 def test_bool_status(self):self.bad(lambda r:r['records'][0]['check'].update(status=False))
 def test_timeout_zero(self):self.bad(lambda r:r['records'][0]['check'].update(timeout=0))
 def test_utf8_one(self):self.bad(lambda r:r['records'][0]['check'].update(valid_utf8=1))
 def test_missing_timeout(self):self.bad(lambda r:r['records'][0]['check'].pop('timeout'))
 def test_missing_spawn(self):self.bad(lambda r:r['records'][0]['check'].pop('spawn_error'))
 def test_spawn(self):self.bad(lambda r:r['records'][0]['check'].update(spawn_error='OSError'))
 def test_signal(self):self.bad(lambda r:r['records'][0]['check'].update(status=-11))
 def test_raw_mismatch(self):self.bad(lambda r:r['records'][0]['check'].update(stdout_base64='/w=='))
 def test_raw_hash(self):self.bad(lambda r:r['records'][0]['check'].update(stdout_sha256='0'*64))
 def test_noncanonical_base64(self):self.bad(lambda r:r['records'][0]['check'].update(stdout_base64='\n'))
 def test_crash(self):self.bad(lambda r:r['records'][0].update(check=stage(['/candidate'],str(ROOT),stderr='Segmentation fault')))
 def test_omitted(self):self.bad(lambda r:r['records'].pop())
 def test_extra(self):self.bad(lambda r:r['records'].append(copy.deepcopy(r['records'][0])))
 def test_duplicate(self):self.bad(lambda r:r['records'].__setitem__(1,copy.deepcopy(r['records'][0])))
 def test_unknown_name(self):self.bad(lambda r:r['records'][0].update(name='unknown'))
 def test_source(self):self.bad(lambda r:r['records'][0].update(source='other.f90'))
 def test_source_hash(self):self.bad(lambda r:r['records'][0].update(sha256='0'*64))
 def test_mode_type(self):self.bad(lambda r:r['records'][0].update(gnu_run=1))
 def test_mode_flip(self):self.bad(lambda r:r['records'][0].update(gnu_run=False))
 def test_extra_stage(self):self.bad(lambda r:r['records'][0].update(hidden_stage={}))
 def test_invocation(self):self.bad(lambda r:r['records'][0]['check'].update(argv=['/candidate','wrong']))
 def test_cwd(self):self.bad(lambda r:r['records'][0]['check'].update(cwd='/wrong'))
 def test_candidate_before(self):self.bad(lambda r:r.update(candidate_sha256_before='0'*64))
 def test_candidate_after(self):self.bad(lambda r:r.update(candidate_sha256_after='0'*64))
 def test_gnu_before(self):self.bad(lambda r:r.update(gnu_sha256_before='0'*64))
 def test_gnu_after(self):self.bad(lambda r:r.update(gnu_sha256_after='0'*64))
 def test_version_after(self):self.bad(lambda r:r.update(version_after=stage(['/candidate','--version'],str(ROOT),stdout='wrong\n')))
 def test_gnu_version(self):self.bad(lambda r:r.update(gnu_version_before=stage(['/gnu','--version'],str(ROOT),stdout='wrong\n')))
 def test_inputs_before(self):self.bad(lambda r:r['inputs_before'].pop('manifest.json'))
 def test_inputs_after(self):self.bad(lambda r:r['inputs_after'].update({'run_strict.py':'0'*64}))
 def test_runner_exception(self):self.bad(lambda r:r.update(runner_exception='bad'))
 def test_compile_warning(self):self.bad(lambda r:r['records'][0].update(gnu_compile=stage(r['records'][0]['gnu_compile']['argv'],r['records'][0]['cwd'],stderr='warning')))
 def test_forbidden_gnu(self):
  def mutate(r):
   row=next(x for x in r['records']if not x['gnu_run']);row['gnu_execution']=stage([row['cwd']+'/oracle'],row['cwd'])
  self.bad(mutate)
 def test_bad_expected_gnu(self):self.assertTrue(validate(fixture(),M,ROOT,C,'0'*64))
 def test_bad_expected_candidate(self):self.assertTrue(validate(fixture(),M,ROOT,'0'*64,G['sha256']))
 def test_capture_oserror(self):
  with patch('process_contract.subprocess.run',side_effect=OSError('missing')):s=capture(['x'],ROOT)
  self.assertTrue(stage_errors(s));self.assertIn('OSError',s['spawn_error'])
 def test_capture_timeout(self):
  with patch('process_contract.subprocess.run',side_effect=subprocess.TimeoutExpired('x',30,b'out',b'err')):s=capture(['x'],ROOT)
  self.assertTrue(stage_errors(s));self.assertEqual(s['stdout'],'out')
 def test_capture_utf8(self):
  with patch('process_contract.subprocess.run',return_value=subprocess.CompletedProcess(['x'],0,b'\xff',b'')):s=capture(['x'],ROOT)
  self.assertTrue(stage_errors(s));self.assertEqual(base64.b64decode(s['stdout_base64']),b'\xff')
 def test_output_exclusive(self):
  with tempfile.TemporaryDirectory()as d:
   p=pathlib.Path(d)/'out';p.write_text('preserve')
   with self.assertRaises(FileExistsError):reserve_output(p)
   self.assertEqual(p.read_text(),'preserve')
 def test_output_parent_symlink(self):
  with tempfile.TemporaryDirectory()as d:
   p=pathlib.Path(d);(p/'real').mkdir();(p/'link').symlink_to(p/'real',target_is_directory=True)
   with self.assertRaises(OSError):reserve_output(p/'link'/'out')
   self.assertFalse((p/'real/out').exists())
 def test_optimized_subprocess_validation(self):
  code="from test_strict import fixture,M,ROOT,C,G;from validate_results import validate;r=fixture();r['records'].pop();raise SystemExit(0 if validate(r,M,ROOT,C,G['sha256']) else 1)"
  p=subprocess.run([sys.executable,'-O','-c',code],cwd=ROOT,capture_output=True,text=True);self.assertEqual(p.returncode,0,p.stderr)
if __name__=='__main__':unittest.main()
