import copy, hashlib, json, pathlib, shutil, subprocess, sys, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parent.parent
class RunnerGuards(unittest.TestCase):
 def probe(self,mutation,optimized=True):
  with tempfile.TemporaryDirectory() as d:
   r=pathlib.Path(d)
   shutil.copytree(ROOT/'tests',r/'tests',ignore=shutil.ignore_patterns('__pycache__'))
   shutil.copy2(ROOT/'run_strict.py',r/'run_strict.py')
   candidate=r/'candidate';candidate.write_bytes(b'guard-control')
   h=hashlib.sha256(candidate.read_bytes()).hexdigest()
   rows=json.loads((r/'tests/manifest.json').read_text())['cases']
   data={'candidate_sha256':h,'candidate_sha256_after':h,'records':copy.deepcopy(rows)}
   expected=h
   if mutation=='omitted':data['records'].pop()
   elif mutation=='duplicate':data['records'][-1]=copy.deepcopy(data['records'][0])
   elif mutation=='extra':data['records'].append(copy.deepcopy(data['records'][0]))
   elif mutation=='name':data['records'][-1]['name']='unknown'
   elif mutation=='source':data['records'][-1]['source']=data['records'][0]['source']
   elif mutation=='hash':data['records'][-1]['sha256']='0'*64
   elif mutation=='mode':data['records'][-1]['mode']='run'
   elif mutation=='identity':expected='0'*64
   elif mutation=='source_identity':(r/'tests'/rows[0]['source']).write_text('changed')
   elif mutation=='after_identity':data['candidate_sha256_after']='0'*64
   elif mutation=='actual_after_identity':pass
   else:raise ValueError(mutation)
   fake="import json,pathlib,sys\npathlib.Path(sys.argv[sys.argv.index('--output')+1]).write_text("+repr(json.dumps(data))+ ")\n"
   if mutation=='actual_after_identity':fake+="pathlib.Path(sys.argv[sys.argv.index('--candidate')+1]).write_bytes(b'changed')\n"
   (r/'run_probe.py').write_text(fake)
   p=subprocess.run([sys.executable]+(['-O']if optimized else [])+[str(r/'run_strict.py'),'--candidate',str(candidate),'--expected-sha',expected,'--output',str(r/'out.json')],capture_output=True,text=True,timeout=10)
   self.assertNotEqual(p.returncode,0)
   return p.stderr
 def test_omitted(self):self.assertIn('record count differs',self.probe('omitted'))
 def test_duplicate(self):self.assertIn('duplicate record names',self.probe('duplicate'))
 def test_extra(self):self.assertIn('record count differs',self.probe('extra'))
 def test_unknown_name(self):self.assertIn('record names differ',self.probe('name'))
 def test_source_binding(self):self.assertIn('record metadata differs',self.probe('source'))
 def test_source_hash_binding(self):self.assertIn('record metadata differs',self.probe('hash'))
 def test_mode_binding(self):self.assertIn('record metadata differs',self.probe('mode'))
 def test_optimized_identity(self):self.assertIn('candidate identity differs',self.probe('identity'))
 def test_optimized_source_identity(self):self.assertIn('source differs',self.probe('source_identity'))
 def test_reported_after_identity(self):self.assertIn('candidate changed',self.probe('after_identity'))
 def test_actual_after_identity(self):self.assertIn('candidate file changed',self.probe('actual_after_identity'))
 def test_normal_identity(self):self.assertIn('candidate identity differs',self.probe('identity',False))
if __name__=='__main__':unittest.main()
