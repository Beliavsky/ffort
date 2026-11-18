#!/usr/bin/env python3
"""Immediate scalar assignments and PRINT: exact output and no-replay contracts."""
import argparse, subprocess, tempfile, unittest, selectors
from pathlib import Path
CANDIDATE=None
class Immediate(unittest.TestCase):
 def run_repl(self,text,extra=()):
  with tempfile.TemporaryDirectory() as d:
   p=subprocess.run([str(CANDIDATE),'--repl','--nologo','--prompt','',*extra],input=text,text=True,capture_output=True,cwd=d,timeout=20)
  return p
 def good(self,text):
  p=self.run_repl(text);self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def test_output_arrives_before_next_input(self):
  with tempfile.TemporaryDirectory() as d:
   p=subprocess.Popen([str(CANDIDATE),'--repl','--nologo','--prompt',''],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,cwd=d)
   try:
    p.stdin.write(b"print '(A)', 'LIVE'\n");p.stdin.flush()
    with selectors.DefaultSelector() as sel:
     sel.register(p.stdout,selectors.EVENT_READ);self.assertTrue(sel.select(10),'PRINT did not flush while waiting for input')
     self.assertEqual(p.stdout.readline(),b'LIVE\n')
    p.stdin.write(b'.quit!\n');p.stdin.flush();out,err=p.communicate(timeout=10)
    self.assertEqual(p.returncode,0);self.assertEqual(out,b'');self.assertEqual(err,b'')
   finally:
    if p.poll() is None:p.kill();p.communicate()
 def test_defer_check_keeps_source_pending(self):
  p=self.run_repl("print '(A)', 'PENDING'\n.quit!\n",['--defer-check']);self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertEqual(p.stderr,'')
 def test_defer_check_explicit_query_flushes_once(self):
  p=self.run_repl("integer :: n\nn=3\nprint '(A)', 'ONCE'\nn\nn\n.quit!\n",['--defer-check']);self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stdout.split(),['ONCE','3','3'])
 def test_defer_check_rejects_batch_stdin(self):
  p=subprocess.run([str(CANDIDATE),'--defer-check'],input='print *, 1\nend\n',text=True,capture_output=True,timeout=10)
  self.assertNotEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertIn('requires REPL',p.stderr)
 def test_defer_check_rejects_filename(self):
  with tempfile.TemporaryDirectory() as d:
   f=Path(d)/'input.f90';f.write_text('print *, 1\nend\n');p=subprocess.run([str(CANDIDATE),'--defer-check',str(f)],text=True,capture_output=True,timeout=10)
  self.assertNotEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertIn('requires REPL',p.stderr)
 def test_print_before_quit(self):
  self.assertEqual(self.good("print '(A)', 'IMMEDIATE'\n.quit!\n"),'IMMEDIATE\n')
 def test_print_before_eof(self):
  self.assertEqual(self.good("print '(A)', 'EOF'\n"),'EOF\n')
 def test_assignment_then_query(self):
  self.assertEqual(self.good('integer :: n\nn=7\nn\nn=n+2\nn\n.quit!\n').split(),['7','9'])
 def test_no_replay(self):
  self.assertEqual(self.good("integer :: n\nn=1\nprint '(A)', 'ONCE'\nn\nn\nn=n+1\nn\n.quit!\n").split(),['ONCE','1','1','2'])
 def test_explicit_run_repeats_intentionally(self):
  self.assertEqual(self.good("print '(A)', 'TWICE'\n.run\n.quit!\n"),'TWICE\nTWICE\n')
 def test_invalid_query_cannot_undo_print(self):
  p=self.run_repl("print '(A)', 'ALREADY'\nmissing\n.clear\n.quit!\n");self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'ALREADY\n');self.assertTrue(p.stderr)
 def test_unsupported_select_stays_buffered(self):
  self.assertEqual(self.good("integer :: i\ncharacter(len=32) :: scratch\ni=0\nwrite(scratch,\"(I0)\") i\nprint *, i\n.quit!\n"),'')
 def test_loop_explicit_run(self):
  self.assertEqual(self.good("integer :: i\ndo i=1,2\nprint *, i\nend do\n.run\n.quit!\n").split(),['1','2','1','2'])
 def test_unsupported_array_intrinsic_stays_buffered(self):
  self.assertEqual(self.good("integer :: a(2)\na=int(a)\nprint *, a\n.quit!\n"),'')
 def test_comments_do_not_execute(self):
  self.assertEqual(self.good("! print *, 'BAD'\n! n=4\n.quit!\n"),'')
 def test_comparison_query_not_assignment(self):
  self.assertEqual(self.good('integer :: n\nn=3\nn==3\nn/=3\n.quit!\n').split(),['T','F'])
 def test_quoted_equals(self):
  self.assertEqual(self.good("character(len=3) :: s\ns='a=b'\ns\n.quit!\n").strip(),'a=b')
 def test_kind_declaration_rejected_after_assignment(self):
  p=self.run_repl('integer :: n\nn=3\nreal(kind=8) :: later\nn\n.clear\n.quit!\n');self.assertEqual(p.returncode,0);self.assertEqual(p.stdout.split(),['3']);self.assertIn('growth requires',p.stderr)
 def test_runtime_error_not_retried(self):
  p=self.run_repl("integer :: n,z\nn=3\nz=0\nprint '(A)', 'ONCE'\nn=1/z\nn\nn\n.clear\n.quit!\n");self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'ONCE\n');self.assertIn('tainted',p.stderr)
 def test_pending_rng_flushed_once(self):
  p=self.good("real :: x\ncall random_number(x)\nprint *, x\nx\nx\n.quit!\n").split();self.assertEqual(len(p),3);self.assertEqual(p[0],p[1]);self.assertEqual(p[1],p[2])
 def test_clear_resets(self):
  self.assertEqual(self.good('integer :: n\nn=4\n.clear\ninteger :: n\nn=8\nn\n.quit!\n').split(),['8'])
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);a,rest=p.parse_known_args();CANDIDATE=Path(a.candidate).resolve();unittest.main(argv=['test_immediate.py',*rest])
