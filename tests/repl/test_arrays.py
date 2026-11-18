#!/usr/bin/env python3
import argparse,hashlib,json,pathlib,subprocess,tempfile,unittest
CANDIDATE=None
RECORDS=[]
class Arrays(unittest.TestCase):
 def invoke(self,s,defer=False):
  with tempfile.TemporaryDirectory() as d:
   p=subprocess.run([str(CANDIDATE),'--repl','--nologo','--prompt','',*(['--defer-check'] if defer else [])],input=s,text=True,capture_output=True,cwd=d,timeout=20)
  RECORDS.append(dict(source=s,defer=defer,code=p.returncode,stdout=p.stdout,stderr=p.stderr));self.assertEqual(p.returncode,0);return p
 def clean(self,p):self.assertEqual(p.stderr,'');return p.stdout
 def test_broadcast_and_elements(self):
  for defer in (False,True):
   p=self.invoke('integer :: a(-2:1)\na=4\na(-1)=7\na\na(-1)\na\n.quit!\n',defer)
   self.assertEqual(self.clean(p).split(),['4','7','4','4','7','4','7','4','4'])
 def test_partial_vars(self):
  p=self.invoke('integer :: a(0:2)\na(1)=9\n.vars\n.vars\na(1)\n.quit!\n');s=self.clean(p)
  self.assertEqual(s.count('a(0:2) = <1/3 defined>'),2);self.assertEqual(s.count('a(0) = <undefined>'),2);self.assertEqual(s.count('a(1) = 9'),2);self.assertEqual(s.count('a(2) = <undefined>'),2);self.assertEqual(s.splitlines()[-1].strip(),'9')
 def test_vars_bounded(self):
  s=self.clean(self.invoke('integer :: a(20)\na=6\n.vars\n.quit!\n'))
  self.assertIn('<20/20 defined>',s);self.assertIn('a(16) = 6',s);self.assertNotIn('a(17) =',s);self.assertIn('first 16',s)
 def test_if_queries_no_replay(self):
  for defer in (False,True):
   s=self.clean(self.invoke("integer :: a(2)\na=1\nif (a(1)==1) then\na(2)=5\nprint '(A)', 'ONCE'\nendif\na\na\na(2)=a(2)+1\na\n.quit!\n",defer))
   self.assertEqual(s.split(),['ONCE','1','5','1','5','1','6'])
 def test_skipped_undefined(self):
  s=self.clean(self.invoke('integer :: a(2),n\nn=1\nif (.false.) n=a(2)\na(1)=n\na(1)\n.quit!\n'));self.assertEqual(s.split(),['1'])
 def test_runtime_errors_taint(self):
  for expr in ('a(2)','a(3)'):
   p=self.invoke('integer :: a(2)\na(1)=5\n'+expr+'\n.vars\n.clear\ninteger :: n\nn=8\nn\n.quit!\n')
   self.assertEqual(p.stdout.split(),['8']);self.assertIn('tainted',p.stderr.lower())
 def test_empty(self):
  s=self.clean(self.invoke('integer :: a(5:2)\na=5\na\n.vars\n.quit!\n'));self.assertIn('a(5:2) = <0/0 defined>',s)
 def test_logical_real(self):
  s=self.clean(self.invoke('logical :: b(2)\nreal :: x(2)\nb=.false.\nb(1)=.true.\nx=1.5\nx(2)=2.5\nb\nx\n.quit!\n'));self.assertEqual(s.split()[:2],['T','F']);self.assertEqual([float(x) for x in s.split()[2:]],[1.5,2.5])
 def test_edit_requires_run(self):
  p=self.invoke('integer :: a(2)\na=1\na\n.rep 2 a=5\na\n.run\na\n.quit!\n');self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['1','1','5','5'])
 def test_rejected_query_no_deferred_effect(self):
  p=self.invoke("integer :: a(2)\na=1\nprint '(A)', 'FORBIDDEN'\nint(a)\n.clear\n.quit!\n",True);self.assertTrue(p.stderr);self.assertEqual(p.stdout,'')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Arrays));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
