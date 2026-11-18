#!/usr/bin/env python3
"""Independent editor atomicity/no-replay transcripts. All checks survive Python -O."""
import argparse, hashlib, json, pathlib, subprocess, tempfile, unittest
CANDIDATE=None
RECORDS=[]
HEADER='program repl_session\nimplicit none\n'
FOOTER='end program repl_session\n'
class Editor(unittest.TestCase):
 def run_repl(self,source,defer=False,files=None):
  argv=[str(CANDIDATE),'--repl','--nologo','--prompt','',*(['--defer-check'] if defer else [])]
  with tempfile.TemporaryDirectory() as d:
   d=pathlib.Path(d)
   for name,value in (files or {}).items():(d/name).write_text(value)
   p=subprocess.run(argv,input=source,text=True,capture_output=True,cwd=d,timeout=20)
   output_files={str(f.relative_to(d)):f.read_text() for f in d.iterdir() if f.is_file()}
  RECORDS.append(dict(argv=argv,source=source,code=p.returncode,stdout=p.stdout,stderr=p.stderr,files=output_files))
  return p,output_files
 def clean(self,p):
  self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def plain(self,body):return HEADER+body+FOOTER
 def test_numbered_body_and_plain_wrapper(self):
  body='integer :: n\nn=3\n'
  p,_=self.run_repl(body+'.list\n.list -n\n.quit!\n',True);out=self.clean(p)
  a,b=out.split('program repl_session',2)[1:]
  self.assertIn('1  integer :: n\n',a);self.assertIn('2  n=3\n',a);self.assertNotIn('1  program',out)
  self.assertTrue(out.endswith(self.plain(body)))
 def test_delete_ranges(self):
  body='! a\n! b\n! c\n! d\n'
  for command,want in [('.del 2','! a\n! c\n! d\n'),('.del 2:3','! a\n! d\n'),('.del :2','! c\n! d\n'),('.del 3:','! a\n! b\n'),('.del :',''),('.del 1 : 4','')]:
   with self.subTest(command=command):
    p,_=self.run_repl(body+command+'\n.list -n\n.quit!\n',True);self.assertEqual(self.clean(p),self.plain(want))
 def test_insert_before_first_and_after_last(self):
  p,_=self.run_repl('! middle\n.ins 1 ! first\n.ins 3 ! last\n.list -n\n.quit!\n',True)
  self.assertEqual(self.clean(p),self.plain('! first\n! middle\n! last\n'))
 def test_insert_empty_buffer(self):
  p,_=self.run_repl('.ins 1 integer :: n\n.list -n\n.quit!\n');self.assertEqual(self.clean(p),self.plain('integer :: n\n'))
 def test_replace_first_and_last(self):
  p,_=self.run_repl('! a\n! b\n.rep 1 ! first\n.rep 2 ! last\n.list -n\n.quit!\n',True)
  self.assertEqual(self.clean(p),self.plain('! first\n! last\n'))
 def test_invalid_commands_atomic_source(self):
  commands=['.del','.del 0','.del -1','.del +1','.del 2:1','.del 1:3','.del ::','.del 1:2 extra','.del 2147483648','.del 9999999999999999999999999999','.ins 0 x','.ins 4 x','.ins 1x','.ins 1','.rep 3 x','.rep 1','.rep 1   ','.rep -1 x','.rep 999999999999999999999 x','.del 1,2','.del 1.0']
  for command in commands:
   with self.subTest(command=command):
    p,_=self.run_repl('! a\n! b\n'+command+'\n.list -n\n.clear\n.quit!\n',True)
    self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout,self.plain('! a\n! b\n'))
 def test_invalid_edit_preserves_live_state_and_no_gate(self):
  for command in ('.del 99','.rep 3 n=9','.ins 0 n=9','.del 999999999999999999999'):
   with self.subTest(command=command):
    p,_=self.run_repl('integer :: n\nn=3\n'+command+'\nn\nn=n+1\nn\n.clear\n.quit!\n')
    self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['3','4'])
 def test_pending_edit_flushes_new_source_once(self):
  p,_=self.run_repl("integer :: n\nn=3\nprint '(A)', 'ONCE'\n.rep 2 n=8\nn\nn\n.quit!\n",True)
  self.assertEqual(self.clean(p).split(),['ONCE','8','8'])
 def test_executed_edit_gates_queries_vars_and_immediate_lines(self):
  p,_=self.run_repl("integer :: n\nn=3\nprint '(A)', 'ONCE'\n.rep 2 n=8\nn\n.vars\nn=n+1\nprint '(A)', 'PENDING'\nn\n.clear\n.quit!\n")
  self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'ONCE\n');self.assertTrue(p.stderr)
 def test_explicit_successful_run_clears_gate(self):
  p,_=self.run_repl('integer :: n\nn=3\n.rep 2 n=8\n.run\nn\nn=n+1\nn\n.quit!\n')
  self.assertEqual(self.clean(p).split(),['8','9'])
 def test_identical_replacement_still_gates(self):
  p,_=self.run_repl('integer :: n\nn=3\n.rep 2 n=3\nn\n.vars\n.clear\n.quit!\n');self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_compile_failed_run_preserves_gate(self):
  p,_=self.run_repl('integer :: n\nn=3\n.rep 2 n=\n.run\n.rep 2 n=8\nn\n.vars\n.clear\n.quit!\n');self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_runtime_failed_run_preserves_gate(self):
  p,_=self.run_repl('integer :: n,z\nn=3\nz=0\n.rep 2 n=1/z\n.run\n.rep 2 n=8\nn\n.vars\n.clear\n.quit!\n');self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_stop_zero_run_preserves_gate(self):
  p,_=self.run_repl('integer :: n\nn=3\n.ins 3 stop 0\n.run\n.del 3\nn\n.vars\n.clear\n.quit!\n');self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_save_and_load_preserve_gate(self):
  p,files=self.run_repl('integer :: n\nn=3\n.rep 2 n=8\n.save edited.f90\n.load edited.f90\nn\n.vars\n.run\nn\n.quit!\n')
  self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.splitlines(),['Saved source to edited.f90',' 8']);self.assertEqual(files['edited.f90'],self.plain('integer :: n\nn=8\n'))
 def test_load_another_source_cannot_bypass_gate(self):
  p,_=self.run_repl('integer :: n\nn=3\n.rep 2 n=8\n.load other.f90\nm\n.vars\n.clear\n.quit!\n',files={'other.f90':self.plain('integer :: m\nm=12\n')})
  self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout,'')
 def test_edit_after_taint_requires_explicit_run(self):
  p,_=self.run_repl('integer :: n,z\nn=3\nz=0\nn=1/z\n.rep 4 n=7\nn\n.vars\n.run\nn\n.quit!\n')
  self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['7'])
 def test_declaration_edit_requires_run_but_unfreezes_layout(self):
  p,_=self.run_repl('integer :: n\nn=3\n.rep 1 real :: n\n.ins 2 real :: x\n.ins 4 x=2.0\n.run\nn\nx\n.quit!\n')
  self.assertEqual([float(x) for x in self.clean(p).split()],[3.0,2.0])
 def test_clear_releases_gate(self):
  p,_=self.run_repl('integer :: n\nn=3\n.rep 2 n=8\n.clear\ninteger :: n\nn=9\nn\n.quit!\n');self.assertEqual(self.clean(p).split(),['9'])
 def test_overlong_edit_atomic_and_session_usable(self):
  p,_=self.run_repl('integer :: n\nn=3\n.rep 2 '+('x'*4096)+'\nn\n.clear\n.quit!\n');self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['3'])
 def test_line_count_limit_failed_insert_atomic(self):
  body='! x\n'*10000
  p,_=self.run_repl(body+'.ins 1 ! extra\n.list -n\n.clear\n.quit!\n',True);self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout,self.plain(body))
 def test_byte_limit_failed_insert_atomic(self):
  body=('!'+('x'*3999)+'\n')*262
  p,files=self.run_repl(body+'.ins 1 !'+('y'*1000)+'\n.save full.f90\n.clear\n.quit!\n',True)
  self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(files['full.f90'],self.plain(body))
 def test_max_line_number_visible(self):
  p,_=self.run_repl('! x\n'*10000+'.list\n.quit!\n',True);out=self.clean(p);self.assertNotIn('****',out);self.assertIn('10000  ! x\n',out)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Editor));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
