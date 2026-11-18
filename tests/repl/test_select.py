#!/usr/bin/env python3
"""Retained SELECT CASE transcript contract."""
import argparse,json,subprocess,tempfile,unittest
from pathlib import Path
CANDIDATE=None
class Select(unittest.TestCase):
 def run_repl(self,text,defer=False):
  with tempfile.TemporaryDirectory() as d:
   args=[str(CANDIDATE),'--repl','--nologo','--prompt','']
   if defer:args+=['--defer-check']
   return subprocess.run(args,input=text,text=True,capture_output=True,cwd=d,timeout=20)
 def clean(self,text,defer=False):
  p=self.run_repl(text+'\n.quit!\n',defer);self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def test_integer_list_default_middle(self):
  s=self.clean('integer :: x,y\nx=3\ny=0\nselect case(x)\ncase(1,2)\ny=1\ncase default\ny=8\ncase(3:5)\ny=3\nend select\ny\ny\n.vars y');self.assertEqual(s.splitlines(),[' 3',' 3','y = 3'])
 def test_default_first(self):
  self.assertEqual(self.clean('integer :: x\nx=9\nselect case(x)\ncase default\nx=4\ncase(1)\nx=2\nend select\nx').splitlines(),[' 4'])
 def test_no_match(self):self.assertEqual(self.clean('integer :: x\nx=8\nselect case(x)\ncase(1)\nx=1\nend select\nx').splitlines(),[' 8'])
 def test_empty(self):self.assertEqual(self.clean('integer :: x\nx=8\nselect case(x)\nend select\nx').splitlines(),[' 8'])
 def test_logical(self):self.assertEqual(self.clean('logical :: x\ninteger :: n\nx=.true.\nselect case(x)\ncase(.false.)\nn=0\ncase(.true.)\nn=1\nend select\nn').splitlines(),[' 1'])
 def test_character_padding_range(self):
  self.assertEqual(self.clean('character(len=3) :: c\ninteger :: n\nc="b"\nselect case(c)\ncase(:"a")\nn=1\ncase("b":"d")\nn=2\ncase("e":)\nn=3\nend select\nn').splitlines(),[' 2'])
 def test_integer_constant_expressions(self):self.assertEqual(self.clean('integer :: x\nx=3\nselect case(x)\ncase(1+2)\nx=7\ncase(5:2)\nx=9\nend select\nx').splitlines(),[' 7'])
 def test_nested_if_empty_arm(self):
  s=self.clean('integer :: x,y\nx=1\ny=0\nselect case(x)\ncase(1)\nif(x==1)then\nselect case(y)\ncase(0)\ncase default\ny=9\nend select\nend if\ncase default\ny=8\nend select\ny');self.assertEqual(s.splitlines(),[' 0'])
 def test_loop_composition(self):
  s=self.clean('integer :: i,j,n\nn=0\nouter: do i=1,4\nselect case(i)\ncase(1)\ncycle outer\ncase(4)\nexit outer\ncase default\ndo j=1,2\nn=n+1\nend do\nend select\nend do outer\nn\ni');self.assertEqual(s.splitlines(),[' 4',' 4'])
 def test_selector_evaluated_once(self):self.assertEqual(self.clean('integer :: x\nx=1\nselect case(x)\ncase(1)\nx=2\ncase(2)\nx=9\nend select\nx').splitlines(),[' 2'])
 def test_incomplete_no_effect(self):
  p=self.run_repl("integer :: x\nx=1\nselect case(x)\ncase(1)\nprint '(A)', 'FORBIDDEN'\n.quit!\n");self.assertEqual(p.stdout,'')
 def test_immediate_closed_once(self):
  s=self.clean("integer :: x\nx=1\nselect case(x)\ncase(1)\nprint '(A)', 'ONCE'\nend select\n.list -n\nx\n.vars x");self.assertEqual(s.count('\nONCE\n')+s.startswith('ONCE\n'),1);self.assertIn('x = 1',s)
 def test_deferred_query_once(self):
  s=self.clean("integer :: x\nx=1\nselect case(x)\ncase(1)\nprint '(A)', 'ONCE'\nend select\nx\nx",True);self.assertEqual(s.count('ONCE'),1)
 def test_runtime_failure_taints(self):
  p=self.run_repl("integer :: x\nx=1\nselect case(x)\ncase(1)\nprint '(A)', 'ONCE'\nx=1/0\nend select\n.vars\nx\n.clear\n.quit!\n");self.assertEqual(p.stdout.count('ONCE'),1);self.assertTrue(p.stderr)
 def test_undefined_selector_taints(self):
  p=self.run_repl('integer :: x\nselect case(x)\ncase default\nx=1\nend select\nx\n.clear\n.quit!\n');self.assertTrue(p.stderr);self.assertEqual(p.stdout,'')
 def test_explicit_run_resets(self):
  s=self.clean("integer :: x\nx=1\nselect case(x)\ncase(1)\nprint '(A)', 'ONCE'\nx=2\nend select\n.run\nx");self.assertEqual(s.count('ONCE'),2);self.assertTrue(s.endswith(' 2\n'))
 def test_source_preserved(self):
  s=self.clean('integer :: x\nx=1\nselect case(x)\ncase(1)\nx=2\nend select\nx\n.list -n');self.assertIn('select case(x)\ncase(1)\nx=2\nend select',s)
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('--candidate',required=True);a.add_argument('--report');o=a.parse_args();CANDIDATE=Path(o.candidate).resolve(strict=True)
 r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Select))
 if o.report:Path(o.report).write_text(json.dumps(dict(status='passed' if r.wasSuccessful() else 'failed',tests=r.testsRun),indent=2)+'\n')
 raise SystemExit(not r.wasSuccessful())
