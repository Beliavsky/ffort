import unittest,tempfile,pathlib,json,subprocess,sys,os,shutil
W=pathlib.Path(__file__).resolve().parent
class Harness(unittest.TestCase):
 def candidate(self,case,mutation=None,source_bad=False):
  with tempfile.TemporaryDirectory() as td:
   d=pathlib.Path(td);(d/'tests').mkdir();shutil.copy2(W/'run_tests.py',d/'run_tests.py');p=d/'tests'/(case['name']+'.f90');shutil.copy2(W/'tests'/p.name,p)
   if source_bad:p.write_text('end\n')
   (d/'manifest.json').write_text(json.dumps([case]));mock=d/'mock'
   mock.write_text('#!/usr/bin/env python3\nimport sys,json,pathlib\nc=json.loads(pathlib.Path(__file__).with_name("manifest.json").read_text())[0]\nphase="check" if "--check" in sys.argv else "run"\ncode=1 if c["mode"]=="reject" else 2 if phase=="run" and c["mode"]!="run" else 0\nout="" if phase=="check" or c["mode"]!="run" else c["stdout"]\nerr=c.get("diagnostic","").replace("{source}",sys.argv[-1]) if code else ""\n'+(mutation or '')+'\nsys.stdout.write(out);sys.stderr.write(err);sys.exit(code)\n');mock.chmod(0o755)
   r=subprocess.run([sys.executable,str(d/'run_tests.py'),'--candidate',str(mock),'--result',str(d/'r.json')],capture_output=True,text=True)
   return r.returncode,json.loads((d/'r.json').read_text())
 def test_valid(self):
  for c in json.loads((W/'manifest.json').read_text()):self.assertEqual(self.candidate(c)[0],0,c['name'])
 def test_status_phase(self):
  c=next(x for x in json.loads((W/'manifest.json').read_text()) if x['mode']=='reject')
  for m in ['code=0','code=2','code=-11','code=0 if phase=="check" else code']:
   self.assertEqual(self.candidate(c,m)[0],1)
 def test_diagnostic(self):
  c=next(x for x in json.loads((W/'manifest.json').read_text()) if x['mode']=='reject')
  for m in ['err=err.replace(sys.argv[-1],"wrong.f90")','err=err.replace(":3:",":4:")','err=err.replace(":12:",":13:")','err=""']:
   self.assertEqual(self.candidate(c,m)[0],1)
 def test_streams(self):
  c=json.loads((W/'manifest.json').read_text())[1]
  for m in ['err="leak"','out="leak"','out="leak" if phase=="check" else out']:
   self.assertEqual(self.candidate(c,m)[0],1)
 def test_records(self):
  c=json.loads((W/'manifest.json').read_text())[0]
  for value in ['0 0 1 1 2 4 3 9\n','0 0\n1 1\n2 4\n3 9','0 0\n1 1\n2 4\n3 9\n\n','0 0\n1 1\n2 4\n3 9 0\n']:
   self.assertEqual(self.candidate(c,'out='+repr(value)+' if phase=="run" else out')[0],1)
 def test_source(self):
  c=json.loads((W/'manifest.json').read_text())[0];code,r=self.candidate(c,source_bad=True);self.assertEqual(code,1);self.assertNotIn('run',r['cases'][0])
 def test_gnu_rejections(self):
  c=next(x for x in json.loads((W/'manifest.json').read_text()) if x['mode']=='reject')
  for status,message,expected in [(1,'Error: invalid',0),(0,'',1),(2,'Error: invalid',1),(-11,'crash',1),(1,'internal compiler error',1),(1,'Segmentation fault',1),(1,'Backtrace:',1)]:
   with tempfile.TemporaryDirectory() as td:
    d=pathlib.Path(td);(d/'tests').mkdir();shutil.copy2(W/'run_gnu.py',d/'run_gnu.py');shutil.copy2(W/'tests'/(c['name']+'.f90'),d/'tests'/(c['name']+'.f90'));(d/'manifest.json').write_text(json.dumps([c]));mock=d/'mock';mock.write_text('#!/usr/bin/env python3\nimport sys\nsys.stderr.write('+repr(message)+')\nsys.exit('+str(status)+')\n');mock.chmod(0o755)
    r=subprocess.run([sys.executable,str(d/'run_gnu.py'),str(mock)],capture_output=True,text=True);self.assertEqual(r.returncode,expected)
if __name__=='__main__':unittest.main()
