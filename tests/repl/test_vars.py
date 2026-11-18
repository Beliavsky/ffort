#!/usr/bin/env python3
"""Independent .vars transcripts, including pending suffix and no replay."""
import argparse, subprocess, tempfile, unittest
from pathlib import Path
CANDIDATE=None
class Vars(unittest.TestCase):
 def run_repl(self,text):
  with tempfile.TemporaryDirectory() as d:
   p=subprocess.run([str(CANDIDATE),'--repl','--defer-check','--nologo','--prompt',''],input=text,text=True,capture_output=True,cwd=d,timeout=15)
  return p
 def clean(self,p):
  self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def test_empty(self):self.assertEqual(self.clean(self.run_repl('.vars\n.quit!\n')),'(no variables)\n')
 def test_undefined(self):self.assertEqual(self.clean(self.run_repl('integer :: n\n.vars\n.vars\n.quit!\n')),'n = <undefined>\nn = <undefined>\n')
 def test_integer_pending_once(self):
  p=self.run_repl("integer :: n\nn=2\nprint '(A)', 'ONCE'\n.vars\n.vars\nn=n+3\n.vars\n.quit!\n")
  self.assertEqual(self.clean(p),'ONCE\nn = 2\nn = 2\nn = 5\n')
 def test_defined_types(self):
  p=self.run_repl('real :: r\nlogical :: ok\ncharacter(len=4) :: s\nr=2.5\nok=.true.\ns="a"\n.vars\n.quit!\n')
  lines=self.clean(p).splitlines();self.assertEqual(float(lines[0].split('=')[1]),2.5);self.assertEqual(lines[1],'ok = T');self.assertEqual(lines[2],'s = "a   "')
 def test_rng_no_replay(self):
  p=self.run_repl("real :: r\ncall random_number(r)\nprint '(A)', 'ONCE'\n.vars\n.vars\ncall random_number(r)\n.vars\n.quit!\n")
  lines=self.clean(p).splitlines();self.assertEqual(lines[0],'ONCE');self.assertEqual(lines[1],lines[2]);self.assertNotEqual(lines[2],lines[3]);self.assertEqual(len(lines),4)
 def test_no_source_rewrite(self):
  p=self.run_repl('integer :: n\nn=2\n.vars\n.list\n.quit!\n');s=self.clean(p);self.assertNotIn('.vars',s);self.assertIn('n=2',s)
 def test_unsupported_does_not_flush(self):
  p=self.run_repl("integer :: n(2,2)\nprint '(A)', 'FORBIDDEN'\n.vars\n.clear\n.quit!\n");self.assertEqual(p.stdout,'');self.assertTrue(p.stderr);self.assertEqual(p.returncode,0)
 def test_tainted_no_retry(self):
  p=self.run_repl("integer :: n\nprint '(A)', 'ONCE'\nn=1/0\n.vars\n.vars\n.clear\n.quit!\n");self.assertLessEqual(p.stdout.count('ONCE'),1);self.assertTrue(p.stderr);self.assertEqual(p.returncode,0)
 def test_general_run_not_replayed(self):
  p=self.run_repl("integer :: i\ncharacter(len=32) :: scratch\ni=0\nwrite(scratch,\"(I0)\") i\nprint '(A)', 'ONCE'\n.run\n.vars\n.clear\n.quit!\n");self.assertEqual(p.stdout,'ONCE\n');self.assertTrue(p.stderr);self.assertEqual(p.returncode,0)
 def test_query_and_inspection_share_values(self):
  p=self.run_repl('integer :: n\nn=2\nn\n.vars\nn=n+1\n.vars\nn\n.quit!\n');s=self.clean(p)
  self.assertEqual(s.splitlines(),[' 2','n = 2','n = 3',' 3'])
 def test_clear_resets_layout(self):
  p=self.run_repl('integer :: n\nn=2\n.vars\n.clear\ninteger :: k\nk=8\n.vars\n.quit!\n')
  self.assertEqual(self.clean(p),'n = 2\nk = 8\n')
 def test_unknown_filter_rejected(self):
  p=self.run_repl('integer :: n\nn=2\n.vars missing\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('--candidate',required=True);o=a.parse_args();CANDIDATE=Path(o.candidate).resolve(strict=True)
 r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Vars));raise SystemExit(not r.wasSuccessful())
