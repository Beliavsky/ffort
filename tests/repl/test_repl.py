#!/usr/bin/env python3
"""Independent black-box REPL/CLI contracts. No compiler/runtime imports.
Run: python -B tests/repl/test_repl.py --candidate /absolute/interpreter
Optional --report writes an exclusive JSON receipt, retaining raw transcripts.
"""
import argparse,base64,errno,hashlib,json,os,pty,select,subprocess,tempfile,termios,time,unittest
from pathlib import Path

CANDIDATE=None
RECORDS=[]

def record(args,stdin,code,out,err,transport='pipe'):
 row=dict(command=args,stdin_b64=base64.b64encode(stdin).decode(),returncode=code,
  stdout_b64=base64.b64encode(out).decode(),stderr_b64=base64.b64encode(err).decode(),transport=transport)
 RECORDS.append(row)
 return code,out.decode('utf-8'),err.decode('utf-8')

class Repl(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(prefix='ffort repl contract ');self.addCleanup(self.tmp.cleanup);self.cwd=Path(self.tmp.name)
 def pipe(self,text,args=()):
  argv=[str(CANDIDATE),*args];data=text.encode()
  try:p=subprocess.run(argv,input=data,capture_output=True,cwd=self.cwd,timeout=15)
  except subprocess.TimeoutExpired as ex:
   record(argv,data,None,ex.stdout or b'',ex.stderr or b'',transport='pipe-timeout');raise
  return record(argv,data,p.returncode,p.stdout,p.stderr)
 def repl(self,text,extra=()):return self.pipe(text,('--repl','--defer-check','--nologo','--prompt','',*extra))
 def ok(self,r,output=None):
  code,out,err=r;self.assertEqual(code,0,repr(r));self.assertEqual(err,'',repr(r))
  if output is not None:self.assertEqual(out,output)
  return out
 def test_forced_pipe_run(self):
  self.ok(self.repl("print '(A)', 'REPL_RUN_17'\n.run\n.quit!\n"),'REPL_RUN_17\n')
 def test_buffer_has_no_effect_until_run(self):
  self.ok(self.repl("print '(A)', 'MUST_NOT_EXECUTE'\n.quit!\n"),'')
 def test_clear_removes_pending_source(self):
  self.ok(self.repl("print '(A)', 'STALE_BUFFER'\n.clear\nprint '(A)', 'CLEAN_BUFFER'\n.run\n.quit!\n"),'CLEAN_BUFFER\n')
 def test_eof_never_implicitly_runs(self):
  self.ok(self.repl("print '(A)', 'EOF_MUST_NOT_RUN'\n"),'')
 def test_eof_after_explicit_run(self):
  self.ok(self.repl("print '(A)', 'EOF_AFTER_RUN'\n.run\n"),'EOF_AFTER_RUN\n')
 def test_empty_eof(self):self.ok(self.repl(''),'')
 def test_dot_alias_explicitly_runs(self):
  self.ok(self.repl("print '(A)', 'DOT_RUN'\n.\n.quit!\n"),'DOT_RUN\n')
 def test_oversized_line_is_drained_and_session_recovers(self):
  r=self.repl('!'+('x'*4096)+"\n.clear\nprint '(A)', 'AFTER_LONG_LINE'\n.run\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'AFTER_LONG_LINE\n');self.assertTrue(r[2].strip())

 def test_repeat_runs_have_fresh_allocation_state(self):
  source="integer, allocatable :: a(:)\nallocate(a(1))\na(1)=29\nprint '(I0)', a(1)\n"
  self.ok(self.repl(source+'.run\n.run\n.quit!\n'),'29\n29\n')
 def test_state_query_does_not_replay(self):
  r=self.repl("print '(A)', 'SIDE_EFFECT_ONCE'\n.run\n.unknown_command\n.clear\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1].count('SIDE_EFFECT_ONCE'),1,repr(r));self.assertIn('unsupported command',(r[1]+r[2]).lower())
 def test_unknown_command_keeps_buffer_and_recovers(self):
  r=self.repl("print '(A)', 'AFTER_UNKNOWN'\n.not_a_command\n.run\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1].count('AFTER_UNKNOWN'),1);self.assertIn('unsupported command',(r[1]+r[2]).lower())
 def test_implicit_none_is_default(self):
  r=self.repl("undeclared_repl_variable=7\n.run\n.clear\nprint '(A)', 'AFTER_COMPILE_ERROR'\n.run\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'AFTER_COMPILE_ERROR\n');self.assertTrue(r[2].strip(),repr(r));self.assertIn('undeclared_repl_variable',r[2].lower())
 def test_syntax_error_recovery(self):
  r=self.repl("integer ::\n.run\n.clear\nprint '(A)', 'AFTER_SYNTAX_ERROR'\n.run\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'AFTER_SYNTAX_ERROR\n');self.assertTrue(r[2].strip())
 def test_runtime_error_recovery(self):
  r=self.repl("integer :: a(1), i\ni=2\nprint *, a(i)\n.run\n.clear\nprint '(A)', 'AFTER_RUNTIME_ERROR'\n.run\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'AFTER_RUNTIME_ERROR\n');self.assertTrue(r[2].strip())
 def test_list_reports_source_without_execution(self):
  r=self.repl("integer :: i\ni=41\n.list\n.quit!\n");out=self.ok(r)
  self.assertIn('implicit none',out.lower());self.assertIn('integer :: i',out);self.assertIn('i=41',out)
 def test_help_lists_bounded_commands(self):
  out=self.ok(self.repl('.help\n.quit!\n'))
  for cmd in ('.run','.list','.clear','.quit','.help'):self.assertIn(cmd,out)
 def test_prompt_control(self):
  r=self.pipe('.quit!\n',('--repl','--nologo','--prompt','CUSTOM_REPL> '));self.ok(r,'CUSTOM_REPL> ')
 def test_pipe_without_filename_is_batch_not_repl(self):
  self.ok(self.pipe("program stdin_case\nimplicit none\nprint '(A)', 'BATCH_STDIN'\nend program\n"),'BATCH_STDIN\n')
 def test_batch_check_does_not_execute(self):
  r=self.pipe("program stdin_case\nprint '(A)', 'NOT_EXECUTED_CHECK'\nend program\n",('--check',))
  self.assertEqual(r[0],0,repr(r));self.assertNotIn('NOT_EXECUTED_CHECK',r[1]);self.assertEqual(r[2],'')
 def test_batch_stdin_compile_error_status(self):
  r=self.pipe('program bad\nimplicit none\nmissing_variable=3\nend program\n');self.assertEqual(r[0],1,repr(r));self.assertTrue(r[2].strip())
 def test_source_file_cli_unchanged(self):
  p=self.cwd/'source with spaces.f90';p.write_text("program file_case\nprint '(A)', 'FILE_SOURCE'\nend program\n")
  self.ok(self.pipe('ignored stdin\n',(str(p),)),'FILE_SOURCE\n')
 def test_batch_step_limit(self):
  r=self.pipe('program forever\ninteger :: i\ni=0\ndo\ni=i+1\nend do\nend program\n',('--max-steps','30'))
  self.assertEqual(r[0],2,repr(r));self.assertTrue(r[2].strip())
 def test_repl_step_limit_recovers(self):
  r=self.repl("integer :: i\ni=0\ndo\ni=i+1\nend do\n.run\n.clear\nprint '(A)', 'AFTER_LIMIT'\n.run\n.quit!\n",('--max-steps','30'))
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'AFTER_LIMIT\n');self.assertTrue(r[2].strip())
 def test_interactive_alias(self):
  self.ok(self.pipe("print '(A)', 'INTERACTIVE_ALIAS'\n.run\n.quit!\n",('--interactive','--defer-check','--nologo','--prompt','')),'INTERACTIVE_ALIAS\n')
 def test_forced_repl_rejects_batch_only_combinations(self):
  p=self.cwd/'existing.f90';p.write_text('program x\nend program\n')
  for args in (('--repl','--check'),('--repl','--input','11=missing.txt'),('--repl',str(p))):
   with self.subTest(args=args):
    r=self.pipe("print '(A)', 'MUST_NOT_RUN_OPTION_ERROR'\n.run\n",args)
    self.assertEqual(r[0],1,repr(r));self.assertTrue(r[2].strip());self.assertNotIn('MUST_NOT_RUN_OPTION_ERROR',r[1])
 def test_prompt_length_bound(self):
  r=self.pipe('.quit!\n',('--repl','--prompt','x'*129));self.assertEqual(r[0],1,repr(r));self.assertTrue(r[2].strip())
 def test_prompt_exact_bound(self):
  self.ok(self.pipe('.quit!\n',('--repl','--nologo','--prompt','p'*128)),'p'*128)
 def test_batch_stdin_read_failure(self):
  fd=os.open(self.cwd,os.O_RDONLY)
  try:
   args=[str(CANDIDATE)];p=subprocess.run(args,stdin=fd,capture_output=True,cwd=self.cwd,timeout=15)
   r=record(args,b'',p.returncode,p.stdout,p.stderr,transport='directory-stdin')
  finally:os.close(fd)
  self.assertEqual(r[0],1,repr(r));self.assertTrue(r[2].strip())
 def test_batch_source_size_bound(self):
  r=self.pipe('!'+('x'*(1024*1024))+'\n');self.assertEqual(r[0],1,repr(r));self.assertTrue(r[2].strip())
 def test_repl_buffer_byte_bound_recovers(self):
  r=self.repl(('!'+('x'*3999)+'\n')*270+".clear\nprint '(A)', 'AFTER_BYTE_BOUND'\n.run\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'AFTER_BYTE_BOUND\n');self.assertTrue(r[2].strip())
 def test_repl_line_count_bound_recovers(self):
  r=self.repl('! comment\n'*10001+".clear\nprint '(A)', 'AFTER_LINE_BOUND'\n.run\n.quit!\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'AFTER_LINE_BOUND\n');self.assertTrue(r[2].strip())
 def test_noargs_terminal_enters_repl_before_eof(self):
  master,slave=pty.openpty();attrs=termios.tcgetattr(slave);attrs[3]&=~termios.ECHO;termios.tcsetattr(slave,termios.TCSANOW,attrs)
  p=subprocess.Popen([str(CANDIDATE)],stdin=slave,stdout=slave,stderr=slave,cwd=self.cwd,close_fds=True);os.close(slave)
  raw=bytearray();data=b"print '(A)', 'TTY_ONLY_RESULT'\n.quit!\n";sent=False;deadline=time.monotonic()+15
  try:
   while time.monotonic()<deadline:
    readable,_,_=select.select([master],[],[],0.1)
    if readable:
     try:chunk=os.read(master,65536)
     except OSError as ex:
      if ex.errno==errno.EIO:break
      raise
     if not chunk:break
     raw.extend(chunk)
     if not sent and (b'> ' in raw or b'ffort>' in raw):os.write(master,data);sent=True
    if p.poll() is not None and not readable:break
   if p.poll() is None:
    p.kill();p.wait();record([str(CANDIDATE)],data,p.returncode,bytes(raw),b'',transport='pty-timeout');self.fail('TTY REPL did not prompt/quit within deadline: '+repr(bytes(raw)))
   r=record([str(CANDIDATE)],data,p.returncode,bytes(raw),b'',transport='pty')
   self.assertTrue(sent,'No prompt before input/EOF');self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1].count('TTY_ONLY_RESULT'),1,repr(r))
  finally:
   if p.poll() is None:p.kill();p.wait()
   os.close(master)

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True);ap.add_argument('--report');a=ap.parse_args();CANDIDATE=Path(a.candidate).resolve(strict=True)
 if a.report and os.path.lexists(a.report):ap.error('report already exists')
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();suite=unittest.defaultTestLoader.loadTestsFromTestCase(Repl);r=unittest.TextTestRunner(verbosity=2).run(suite)
 after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();passed=r.wasSuccessful() and before==after
 if a.report:
  with open(a.report,'x') as f:json.dump(dict(status='passed' if passed else 'failed',candidate=str(CANDIDATE),candidate_sha256=before,candidate_after_sha256=after,tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),records=RECORDS),f,indent=2);f.write('\n')
 raise SystemExit(0 if passed else 1)
