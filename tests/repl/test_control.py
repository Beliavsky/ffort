#!/usr/bin/env python3
"""Independent closed scalar conditional transcripts; unittest checks survive -O."""
import argparse,hashlib,json,pathlib,subprocess,tempfile,unittest,selectors
CANDIDATE=None
RECORDS=[]
class Control(unittest.TestCase):
 def invoke(self,source,defer=False,batch=False):
  argv=[str(CANDIDATE)] if batch else [str(CANDIDATE),'--repl','--nologo','--prompt','',*(['--defer-check'] if defer else [])]
  with tempfile.TemporaryDirectory() as d:p=subprocess.run(argv,input=source,text=True,capture_output=True,cwd=d,timeout=20)
  RECORDS.append(dict(argv=argv,source=source,code=p.returncode,stdout=p.stdout,stderr=p.stderr));return p
 def clean(self,p):self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def oracle(self,body):return self.clean(self.invoke('program oracle\nimplicit none\n'+body+'end program oracle\n',batch=True))
 def test_true_false_blocks_both_modes(self):
  for flag in ('.true.','.false.'):
   for defer in (False,True):
    body='integer :: n\nlogical :: flag\nn=1\nflag='+flag+'\nif (flag) then\nn=7\nend if\n'
    with self.subTest(flag=flag,defer=defer):self.assertEqual(self.clean(self.invoke(body+'n\nn\n.quit!\n',defer)),self.oracle(body+'print *, n\nprint *, n\n'))
 def test_else_branches_both_modes(self):
  for flag in ('.true.','.false.'):
   for defer in (False,True):
    body='integer :: n\nlogical :: flag\nn=1\nflag='+flag+'\nif (flag) then\nn=7\nelse\nn=9\nend if\n'
    with self.subTest(flag=flag,defer=defer):self.assertEqual(self.clean(self.invoke(body+'n\n.quit!\n',defer)),self.oracle(body+'print *, n\n'))
 def test_nested_all_paths(self):
  for a in ('.true.','.false.'):
   for b in ('.true.','.false.'):
    body=f'integer :: n\nlogical :: a,b\nn=0\na={a}\nb={b}\nif (a) then\nif (b) then\nn=1\nelse\nn=2\nend if\nelse\nif (b) then\nn=3\nelse\nn=4\nend if\nend if\n'
    with self.subTest(a=a,b=b):self.assertEqual(self.clean(self.invoke(body+'n\n.quit!\n')),self.oracle(body+'print *, n\n'))
 def test_else_if_chain(self):
  for spelling in ('else if','elseif'):
   for value in (1,2,3):
    body=f'integer :: n,x\nx={value}\nn=0\nif (x==1) then\nn=11\n{spelling} (x==2) then\nn=22\nelse\nn=33\nend if\n'
    with self.subTest(spelling=spelling,value=value):self.assertEqual(self.clean(self.invoke(body+'n\n.quit!\n')),self.oracle(body+'print *, n\n'))
 def test_single_line_if_immediate_and_deferred(self):
  for flag in ('.true.','.false.'):
   for defer in (False,True):
    body=f'integer :: n\nn=1\nif ({flag}) n=n+1\n'
    with self.subTest(flag=flag,defer=defer):self.assertEqual(self.clean(self.invoke(body+'n\nn\n.quit!\n',defer)),self.oracle(body+'print *, n\nprint *, n\n'))
  self.assertEqual(self.clean(self.invoke("if (.true.) print '(A)', 'SINGLE'\n.quit!\n")),'SINGLE\n')
 def test_skipped_undefined_value_and_bad_domain(self):
  body="integer :: n,u\nreal :: x\nn=3\nif (.false.) then\nn=u\nx=sqrt(-1.0)\nprint *, u\nelse\nn=n+1\nend if\n"
  for defer in (False,True):
   with self.subTest(defer=defer):self.assertEqual(self.clean(self.invoke(body+'n\n.quit!\n',defer)).split(),['4'])
 def test_incomplete_block_no_body_effects(self):
  for tail in ('','else\n',"if (.true.) then\nprint '(A)', 'NESTED'\nend if\n"):
   with self.subTest(tail=tail):
    source="if (.true.) then\nprint '(A)', 'MUST_NOT_RUN'\n"+tail+'.quit!\n'
    self.assertEqual(self.clean(self.invoke(source)),'')
 def test_outer_end_executes_nested_block_once(self):
  body="if (.true.) then\nprint '(A)', 'OUTER'\nif (.true.) then\nprint '(A)', 'INNER'\nend if\nend if\n"
  self.assertEqual(self.clean(self.invoke(body+'.quit!\n')),'OUTER\nINNER\n')
 def test_closure_output_arrives_before_next_input(self):
  with tempfile.TemporaryDirectory() as d:
   p=subprocess.Popen([str(CANDIDATE),'--repl','--nologo','--prompt',''],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,cwd=d)
   try:
    p.stdin.write(b"if (.true.) then\nprint '(A)', 'LIVE_CLOSE'\n");p.stdin.flush()
    with selectors.DefaultSelector() as sel:
     sel.register(p.stdout,selectors.EVENT_READ);self.assertFalse(sel.select(.2),'incomplete IF produced output')
     p.stdin.write(b'end if\n');p.stdin.flush();self.assertTrue(sel.select(10),'END IF did not produce live output');self.assertEqual(p.stdout.readline(),b'LIVE_CLOSE\n')
    p.stdin.write(b'.quit!\n');p.stdin.flush();out,err=p.communicate(timeout=10)
    self.assertEqual(p.returncode,0);self.assertEqual(out,b'');self.assertEqual(err,b'')
    RECORDS.append(dict(transport='live-pipe',source="if (.true.) then\nprint '(A)', 'LIVE_CLOSE'\nend if\n.quit!\n",observed_before_close='',observed_after_close='LIVE_CLOSE\n',code=p.returncode))
   finally:
    if p.poll() is None:p.kill();p.communicate()
 def test_end_if_and_endif_execute_immediately(self):
  for closer in ('end if','endif','END IF','ENDIF'):
   with self.subTest(closer=closer):self.assertEqual(self.clean(self.invoke("if (.true.) then\nprint '(A)', 'CLOSED'\n"+closer+'\n.quit!\n')),'CLOSED\n')
 def test_deferred_complete_block_waits_for_query(self):
  body="integer :: n\nn=2\nif (.true.) then\nn=n+1\nprint '(A)', 'ONCE'\nend if\n"
  self.assertEqual(self.clean(self.invoke(body+'.quit!\n',True)),'')
  self.assertEqual(self.clean(self.invoke(body+'n\nn\n.quit!\n',True)).split(),['ONCE','3','3'])
 def test_queries_and_vars_do_not_replay(self):
  body="integer :: n\nn=1\nif (.true.) then\nn=n+1\nprint '(A)', 'ONCE'\nend if\n"
  for defer in (False,True):
   with self.subTest(defer=defer):
    p=self.invoke(body+'n\n.vars\nn\nn=n+1\nn\n.quit!\n',defer)
    self.assertEqual(self.clean(p).splitlines(),['ONCE',' 2','n = 2',' 2',' 3'])
 def test_rng_no_replay_and_skipped_call(self):
  body='real :: x\ncall random_seed()\ncall random_number(x)\nif (.false.) then\ncall random_number(x)\nelse\nx=abs(x)\nend if\n'
  suffix='if (.true.) then\ncall random_number(x)\nend if\n'
  for defer in (False,True):
   with self.subTest(defer=defer):
    source=body+'x\nx\n'+suffix+'x\nx\n.quit!\n'
    expected=self.oracle(body+'print *, x\nprint *, x\n'+suffix+'print *, x\nprint *, x\n')
    self.assertEqual(self.clean(self.invoke(source,defer)),expected)
 def test_branch_runtime_error_taints_without_retry(self):
  source="integer :: n,z\nn=3\nz=0\nif (.true.) then\nprint '(A)', 'ONCE'\nn=1/z\nend if\nn\n.vars\n.clear\ninteger :: k\nk=8\nk\n.quit!\n"
  p=self.invoke(source);self.assertEqual(p.returncode,0);self.assertEqual(p.stdout.split(),['ONCE','8']);self.assertIn('tainted',p.stderr.lower())
 def test_undefined_condition_taints(self):
  p=self.invoke("logical :: flag\nif (flag) then\nprint '(A)', 'FORBIDDEN'\nend if\n.vars\n.clear\n.quit!\n")
  self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertIn('tainted',p.stderr.lower())
 def test_edit_closed_block_gates_until_run(self):
  source="integer :: n\nn=1\nif (.true.) then\nn=n+1\nprint '(A)', 'ONCE'\nend if\n.rep 4 n=n+4\nn\n.vars\n.run\nn\n.quit!\n"
  p=self.invoke(source);self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['ONCE','ONCE','5'])
 def test_explicit_run_restarts_conditionals(self):
  source="integer :: n\nn=1\nif (.true.) then\nn=n+1\nprint '(A)', 'RUN'\nend if\nn\n.run\nn\nn\n.quit!\n"
  self.assertEqual(self.clean(self.invoke(source)).split(),['RUN','2','RUN','2','2'])
 def test_closed_block_then_later_closed_block(self):
  body='integer :: n\nn=1\nif (.true.) then\nn=n+1\nend if\n'
  tail='if (n==2) then\nn=n+3\nelse\nn=99\nend if\n'
  self.assertEqual(self.clean(self.invoke(body+'n\n'+tail+'n\nn\n.quit!\n')).split(),['2','5','5'])
 def test_invalid_query_does_not_flush_deferred_block(self):
  body="integer :: n\nn=1\nif (.true.) then\nn=n+1\nprint '(A)', 'FORBIDDEN'\nend if\n"
  p=self.invoke(body+'unknown_function(n)\n.clear\n.quit!\n',True);self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout,'')
 def test_incomplete_then_clear_no_effects(self):
  p=self.invoke("if (.true.) then\nprint '(A)', 'FORBIDDEN'\n.clear\nprint '(A)', 'CLEAN'\n.quit!\n");self.assertEqual(self.clean(p),'CLEAN\n')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Control));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
