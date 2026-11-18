#!/usr/bin/env python3
"""Small editor integration smoke contracts; detailed review suite is independent."""
import argparse,pathlib,subprocess,tempfile,unittest
CANDIDATE=None
class Editor(unittest.TestCase):
 def run_repl(self,source,defer=False):
  with tempfile.TemporaryDirectory() as d:
   return subprocess.run([str(CANDIDATE),'--repl','--nologo','--prompt','',*(['--defer-check'] if defer else [])],input=source,text=True,capture_output=True,cwd=d,timeout=20)
 def test_basic_edits(self):
  p=self.run_repl('.ins 1 integer :: n\n.ins 2 n=2\n.rep 2 n=3\n.ins 3 print *, n\n.del 3\n.list -n\n.quit!\n')
  self.assertEqual(p.stderr,'');self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'program repl_session\nimplicit none\ninteger :: n\nn=3\nend program repl_session\n')
 def test_gate_blocks_effects_until_run(self):
  p=self.run_repl("integer :: n\nn=2\nprint '(A)', 'ONCE'\n.rep 2 n=3\nn\n.vars\nprint '(A)', 'LATER'\n.run\nn\n.quit!\n")
  self.assertEqual(p.returncode,0);self.assertEqual(p.stderr.count('source edited'),2);self.assertEqual(p.stdout.count('ONCE'),2);self.assertEqual(p.stdout.count('LATER'),1);self.assertEqual(int(p.stdout.splitlines()[-1]),3)
 def test_failed_edit_preserves_state(self):
  p=self.run_repl('integer :: n\nn=2\n.del 999999999999999999\nn\n.quit!\n')
  self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(int(p.stdout),2)
 def test_pending_edits_need_no_run(self):
  p=self.run_repl('integer :: n\nn=2\n.rep 2 n=5\nn\n.quit!\n',True)
  self.assertEqual(p.stderr,'');self.assertEqual(int(p.stdout),5)
 def test_failed_run_retains_gate(self):
  p=self.run_repl('integer :: n\nn=2\n.rep 2 n=\n.run\nn\n.rep 2 n=4\n.run\nn\n.quit!\n')
  self.assertEqual(p.returncode,0);self.assertIn('source edited',p.stderr);self.assertEqual(int(p.stdout),4)
 def test_load_does_not_bypass_gate(self):
  p=self.run_repl('integer :: n\nn=2\n.rep 2 n=4\n.save draft.f90\n.load draft.f90\nn\n.clear\n8\n.quit!\n')
  self.assertEqual(p.returncode,0);self.assertIn('source edited',p.stderr);self.assertEqual(int(p.stdout.splitlines()[-1]),8)
 def test_numbered_and_plain_listing(self):
  p=self.run_repl('! comment\n\n.list\n.quit!\n')
  self.assertEqual(p.stderr,'');self.assertIn('    1  ! comment\n    2  \n',p.stdout);self.assertIn('       program repl_session',p.stdout)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);a,rest=p.parse_known_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True);unittest.main(argv=['test_editor_smoke.py',*rest])
