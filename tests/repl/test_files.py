#!/usr/bin/env python3
"""Source-only file command contracts; no execution/replay by save/load/quit."""
import argparse, pathlib, subprocess, tempfile, unittest, hashlib, json, os
CANDIDATE=None
HEADER='program repl_session\nimplicit none\n'; FOOTER='end program repl_session\n'
class Files(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.cwd=pathlib.Path(self.temp.name)
 def invoke(self,s):
  p=subprocess.run([str(CANDIDATE),'--repl','--defer-check','--nologo','--prompt',''],input=s.encode(),capture_output=True,cwd=self.cwd,timeout=20)
  return p.returncode,p.stdout.decode(),p.stderr.decode()
 def assert_ok(self,r):self.assertEqual(r[0],0,r);self.assertEqual(r[2],'',r)
 def test_save_does_not_execute_pending(self):
  r=self.invoke("integer :: n\nn=4\nprint *, 'NOT_EXECUTED'\n.save source.f90\n.quit!\n");self.assert_ok(r)
  self.assertNotIn('NOT_EXECUTED',r[1]);self.assertEqual((self.cwd/'source.f90').read_text(),HEADER+"integer :: n\nn=4\nprint *, 'NOT_EXECUTED'\n"+FOOTER)
 def test_quit_autosaves_without_execution(self):
  r=self.invoke("print *, 'NOT_EXECUTED'\n.quit\n");self.assert_ok(r);self.assertNotIn('NOT_EXECUTED',r[1]);self.assertTrue((self.cwd/'main.f90').exists())
 def test_quit_bang_and_eof_do_not_save(self):
  for ending in ('.quit!\n',''):
   r=self.invoke('integer :: n\nn=4\n'+ending);self.assert_ok(r);self.assertFalse(list(self.cwd.iterdir()))
 def test_empty_quit_does_not_save(self):
  r=self.invoke('.quit\n');self.assert_ok(r);self.assertFalse(list(self.cwd.iterdir()))
 def test_collision_safe_autosave(self):
  (self.cwd/'main.f90').write_text('KEEP');(self.cwd/'main1.f90').write_text('KEEP1')
  r=self.invoke('integer :: n\n.quit\n');self.assert_ok(r)
  self.assertEqual((self.cwd/'main.f90').read_text(),'KEEP');self.assertEqual((self.cwd/'main1.f90').read_text(),'KEEP1');self.assertTrue((self.cwd/'main2.f90').exists())
 def test_explicit_no_overwrite(self):
  (self.cwd/'x.f90').write_text('KEEP')
  r=self.invoke('integer :: n\n.save x.f90\n.quit!\n');self.assertNotEqual(r[0],0);self.assertEqual((self.cwd/'x.f90').read_text(),'KEEP')
 def test_quoted_filename(self):
  r=self.invoke('integer :: n\n.save "my source.f90"\n.clear\n.load "my source.f90"\n.list\n.quit!\n');self.assert_ok(r);self.assertIn('integer :: n',r[1]);self.assertTrue((self.cwd/'my source.f90').exists())
 def test_load_no_execution_then_run(self):
  (self.cwd/'s.f90').write_text(HEADER+"print *, 'ONCE'\n"+FOOTER)
  r=self.invoke('.load s.f90\n.run\n.quit!\n');self.assert_ok(r);self.assertEqual(r[1].count('ONCE'),1)
 def test_load_replaces_body_and_resets_values(self):
  (self.cwd/'s.f90').write_text(HEADER+'integer :: n\nn=7\n'+FOOTER)
  r=self.invoke('integer :: n\nn=3\nn\n.load s.f90\nn\n.quit!\n');self.assert_ok(r);self.assertEqual([int(x)for x in r[1].split()], [3,7])
 def test_invalid_load_preserves_session(self):
  (self.cwd/'bad.f90').write_text('arbitrary program')
  r=self.invoke('integer :: n\nn=3\nn\n.load bad.f90\nn\n.quit!\n');self.assertEqual(r[0],0,r);self.assertTrue(r[2]);self.assertEqual([int(x)for x in r[1].split()], [3,3])
 def test_invalid_paths_dont_write(self):
  for command in ('.save x.f90 --overwrite','.save "unterminated','.save ""','.load'):
   r=self.invoke(command+'\n.quit!\n');self.assertNotEqual(r[0],0,r);self.assertFalse(list(self.cwd.iterdir()))
 def test_save_source_not_values_or_query(self):
  r=self.invoke('integer :: n\nn=3\nn\nn=n+2\nn\n.save s.f90\n.quit!\n');self.assert_ok(r)
  self.assertEqual((self.cwd/'s.f90').read_text(),HEADER+'integer :: n\nn=3\nn=n+2\n'+FOOTER)
 def test_crlf_load(self):
  (self.cwd/'s.f90').write_bytes((HEADER+'integer :: n\nn=7\n'+FOOTER).replace('\n','\r\n').encode())
  r=self.invoke('.load s.f90\nn\n.quit!\n');self.assert_ok(r);self.assertEqual(int(r[1].strip()),7)
 def test_bad_bytes_and_long_line_are_rejected(self):
  for body in ('integer :: n\x00\n','!'+'x'*4096+'\n','integer :: n\r\n'.replace('\r\n','\rX\n')):
   (self.cwd/'bad.f90').write_bytes((HEADER+body+FOOTER).encode())
   r=self.invoke('.load bad.f90\n.quit!\n');self.assertNotEqual(r[0],0,r)
 def test_oversize_file_rejected(self):
  (self.cwd/'big.f90').write_bytes(b'x'*1048577);r=self.invoke('.load big.f90\n.quit!\n');self.assertNotEqual(r[0],0,r)
 def test_missing_load_preserves_source(self):
  r=self.invoke('integer :: n\n.load missing.f90\n.list\n.clear\n.quit!\n');self.assertEqual(r[0],0);self.assertIn('integer :: n',r[1]);self.assertTrue(r[2])
 def test_failed_save_preserves_source(self):
  r=self.invoke('integer :: n\n.save missing/dir.f90\n.list\n.clear\n.quit!\n');self.assertEqual(r[0],0);self.assertIn('integer :: n',r[1]);self.assertTrue(r[2])
 def test_load_empty_and_missing_final_newline(self):
  for raw in ('',HEADER+'integer :: n\n'+FOOTER.rstrip('\n')):
   (self.cwd/'bad.f90').write_text(raw)
   r=self.invoke('.load bad.f90\n.quit!\n');self.assertNotEqual(r[0],0,r)
 def test_control_in_path_rejected(self):
  r=self.invoke('.save "bad'+chr(1)+'name"\n.quit!\n');self.assertNotEqual(r[0],0,r);self.assertFalse(list(self.cwd.iterdir()))
 def test_failed_quit_keeps_buffer_and_repl_open(self):
  os.chmod(self.cwd,0o555)
  try:
   r=self.invoke('integer :: n\n.quit\n.list\n.quit!\n')
  finally:os.chmod(self.cwd,0o755)
  self.assertNotEqual(r[0],0,r);self.assertIn('integer :: n',r[1]);self.assertTrue(r[2]);self.assertFalse(list(self.cwd.iterdir()))
 def test_nonregular_load_rejected_promptly(self):
  (self.cwd/'directory').mkdir()
  os.mkfifo(self.cwd/'fifo')
  (self.cwd/'real.f90').write_text(HEADER+'integer :: n\n'+FOOTER)
  (self.cwd/'link.f90').symlink_to('real.f90')
  for name in ('directory','fifo','link.f90','/dev/null'):
   r=self.invoke('.load '+name+'\n.quit!\n');self.assertNotEqual(r[0],0,r);self.assertTrue(r[2])
 def test_draft_roundtrip(self):
  r=self.invoke('integer :: n\ndo n=1,3\n.save draft.f90\n.clear\n.load draft.f90\n.list\n.quit!\n');self.assert_ok(r);self.assertIn('do n=1,3',r[1])
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report');a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Files));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful()and before==after
 if a.report:
  with open(a.report,'x')as f:json.dump(dict(status='passed'if ok else'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate=str(CANDIDATE),candidate_sha256=before,candidate_after_sha256=after),f,indent=2)
 raise SystemExit(0 if ok else 1)
