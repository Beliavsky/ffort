#!/usr/bin/env python3
"""Bounded ofort-like inspection and pre-effect selection validation."""
import argparse,json,subprocess,tempfile,unittest
from pathlib import Path
CANDIDATE=None
class Inspection(unittest.TestCase):
 def run_repl(self,text):
  with tempfile.TemporaryDirectory() as d:
   return subprocess.run([str(CANDIDATE),'--repl','--defer-check','--nologo','--prompt',''],input=text,text=True,capture_output=True,cwd=d,timeout=20)
 def clean(self,text):
  p=self.run_repl(text+'\n.quit!\n');self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def test_selected_order_case_duplicates(self):
  self.assertEqual(self.clean('integer :: a,b\na=1\nb=2\n.vars B a B'),'b = 2\na = 1\nb = 2\n')
 def test_tabs(self):self.assertEqual(self.clean('integer :: a\na=4\n.vars\tA'),'a = 4\n')
 def test_info_metadata_values(self):
  s=self.clean('integer(kind=8) :: a\nreal(kind=8) :: r\nlogical :: l\ncharacter(len=3) :: c\na=7\n.info')
  for x in ('a : INTEGER kind=8 rank=0','a = 7','r : REAL kind=8 rank=0','l : LOGICAL kind=4 rank=0','c : CHARACTER kind=1 rank=0','  len=3','c = <undefined>'):self.assertIn(x,s)
 def test_shapes_sizes_empty_array(self):
  self.assertEqual(self.clean('integer :: a(-2:0),z(3:2),s\n.shapes\n.sizes\n.shapes s\n.sizes s'),'a: 3\nz: 0\na: 3\nz: 0\ns: scalar\ns: scalar\n')
 def test_empty(self):self.assertEqual(self.clean('.vars\n.info\n.shapes\n.sizes'),'(no variables)\n(no variables)\n(no arrays)\n(no arrays)\n')
 def test_scalar_only_array_commands(self):self.assertEqual(self.clean('integer :: a\n.shapes\n.sizes'),'(no arrays)\n(no arrays)\n')
 def test_array_info_undefined(self):
  s=self.clean('integer :: a(-1:1)\na(0)=8\n.info a');self.assertIn('a : INTEGER kind=4 rank=1',s);self.assertIn('<1/3 defined>',s);self.assertIn('a(0) = 8',s)
 def test_pending_once_across_commands(self):
  s=self.clean("integer :: a(2),i\na=3\ni=9\nprint '(A)', 'ONCE'\n.info i\n.shapes a\n.sizes a\n.vars i")
  self.assertEqual(s.count('ONCE'),1);self.assertEqual(s.count('i = 9'),2)
 def test_invalid_names_do_not_flush(self):
  for name in ('missing','a missing','a,','a(1)','"a"','a;','1a','_a','a!x'):
   with self.subTest(name=name):
    p=self.run_repl("integer :: a\na=3\nprint '(A)', 'FORBIDDEN'\n.vars "+name+'\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_all_modes_unknowns_do_not_flush(self):
  for cmd in ('.vars','.info','.shapes','.sizes'):
   p=self.run_repl("integer :: a\nprint '(A)', 'FORBIDDEN'\n"+cmd+' missing\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertIn('unknown inspection name',p.stderr)
 def test_128_names(self):self.assertEqual(self.clean('integer :: a\na=2\n.vars '+' '.join(['a']*128)).count('a = 2'),128)
 def test_129_names_rejected(self):
  p=self.run_repl("integer :: a\nprint '(A)', 'FORBIDDEN'\n.vars "+' '.join(['a']*129)+'\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertIn('128',p.stderr)
 def test_long_identifier(self):
  p=self.run_repl('.vars '+'a'*64+'\n.clear\n.quit!\n');self.assertIn('63',p.stderr)
 def test_boundary_and_case(self):
  for command in ('.infox','.shapesx','.sizesx','.INFO'):
   p=self.run_repl(command+'\n.clear\n.quit!\n');self.assertTrue(p.stderr)
 def test_tainted_does_not_retry(self):
  p=self.run_repl("integer :: a\nprint '(A)', 'ONCE'\na=1/0\n.info\n.shapes\n.sizes\n.vars\n.clear\n.quit!\n");self.assertEqual(p.stdout.count('ONCE'),1);self.assertTrue(p.stderr)
 def test_editor_gate(self):
  p=self.run_repl('integer :: a\na=1\n.vars\n.rep 2 a=2\n.info\n.shapes\n.sizes\n.clear\n.quit!\n');self.assertEqual(p.stdout,'a = 1\n');self.assertEqual(p.stderr.count('source edited'),3)
 def test_source_unchanged(self):
  s=self.clean('integer :: a\na=5\n.info a\n.shapes a\n.sizes a\n.list -n');self.assertIn('integer :: a\na=5\nend program',s);self.assertNotIn('.info',s)
 def test_arrays_display_bounded(self):
  s=self.clean('integer :: a(20)\na=2\n.info a');self.assertIn('first 16 elements',s);self.assertNotIn('a(17)',s)
 def test_unsupported_before_effects(self):
  p=self.run_repl("integer :: a(2,2)\nprint '(A)', 'FORBIDDEN'\n.info a\n.clear\n.quit!\n");self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_rng_retained(self):
  s=self.clean('real :: r\ncall random_number(r)\n.vars r\n.info r\n.shapes r\n.sizes r\n.vars r');lines=[x for x in s.splitlines() if x.startswith('r = ')];self.assertEqual(len(lines),3);self.assertEqual(len(set(lines)),1)
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('--candidate',required=True);a.add_argument('--report');o=a.parse_args();CANDIDATE=Path(o.candidate).resolve(strict=True)
 r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Inspection))
 if o.report:Path(o.report).write_text(json.dumps(dict(status='passed' if r.wasSuccessful() else 'failed',tests=r.testsRun),indent=2)+'\n')
 raise SystemExit(not r.wasSuccessful())
