#!/usr/bin/env python3
"""Independent persistent-session CLI tests, with exact no-replay output oracles.
No runtime imports. Batch execution supplies formatting/RNG comparison only;
explicit marker counts additionally reject deterministic prefix reset-and-replay.
"""
import argparse,base64,hashlib,json,os,subprocess,tempfile,unittest
from pathlib import Path
CANDIDATE=None
RECORDS=[]
class Session(unittest.TestCase):
 def setUp(self):
  t=tempfile.TemporaryDirectory(prefix='ffort scalar session ');self.addCleanup(t.cleanup);self.cwd=Path(t.name)
 def invoke(self,source,repl=True):
  argv=[str(CANDIDATE),*(['--repl','--nologo','--prompt','']if repl else [])];raw=source.encode()
  try:p=subprocess.run(argv,input=raw,capture_output=True,cwd=self.cwd,timeout=15)
  except subprocess.TimeoutExpired as ex:
   RECORDS.append(dict(command=argv,stdin_b64=base64.b64encode(raw).decode(),termination='timeout',stdout_b64=base64.b64encode(ex.stdout or b'').decode(),stderr_b64=base64.b64encode(ex.stderr or b'').decode()));raise
  RECORDS.append(dict(command=argv,stdin_b64=base64.b64encode(raw).decode(),returncode=p.returncode,stdout_b64=base64.b64encode(p.stdout).decode(),stderr_b64=base64.b64encode(p.stderr).decode()))
  return p.returncode,p.stdout.decode(),p.stderr.decode()
 def clean(self,r):
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[2],'',repr(r));return r[1]
 def batch(self,body):return self.clean(self.invoke('program oracle\nimplicit none\n'+body+'end program oracle\n',False))
 def test_queries_preserve_state_without_replaying_effects(self):
  r=self.invoke("integer :: i\ni=4\nprint '(A)', 'EFFECT_ONCE'\ni\ni+1\ni\n.quit\n")
  expected=self.batch("integer :: i\ni=4\nprint '(A)', 'EFFECT_ONCE'\nprint *, i\nprint *, i+1\nprint *, i\n")
  self.assertEqual(self.clean(r),expected);self.assertEqual(r[1].count('EFFECT_ONCE'),1)
 def test_pending_suffix_executes_once(self):
  r=self.invoke("integer :: i\ni=4\nprint '(A)', 'PREFIX_ONCE'\ni\ni=i+3\nprint '(A)', 'SUFFIX_ONCE'\ni\ni\n.quit\n")
  expected=self.batch("integer :: i\ni=4\nprint '(A)', 'PREFIX_ONCE'\nprint *, i\ni=i+3\nprint '(A)', 'SUFFIX_ONCE'\nprint *, i\nprint *, i\n")
  self.assertEqual(self.clean(r),expected)
  for marker in ('PREFIX_ONCE','SUFFIX_ONCE'):self.assertEqual(r[1].count(marker),1)
 def test_queries_are_not_saved_in_source(self):
  r=self.invoke('integer :: i\ni=4\ni+91\n.list\n.quit\n');out=self.clean(r)
  self.assertNotIn('i+91',out);self.assertNotIn('print *, i+91',out);self.assertIn('i=4',out);self.assertIn('integer :: i',out)
 def test_literal_query_does_not_create_stateful_source(self):
  r=self.invoke('13+29\n13+29\n.list\n.quit\n');out=self.clean(r)
  self.assertNotIn('13+29',out);prefix=self.batch('print *, 13+29\nprint *, 13+29\n');self.assertTrue(out.startswith(prefix),repr(out))
 def test_vars_is_unsupported_and_never_replays(self):
  r=self.invoke("integer :: i\ni=4\nprint '(A)', 'VARS_EFFECT_ONCE'\ni\n.vars\ni\n.clear\n.quit\n")
  expected=self.batch("integer :: i\ni=4\nprint '(A)', 'VARS_EFFECT_ONCE'\nprint *, i\nprint *, i\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],expected);self.assertEqual(r[1].count('VARS_EFFECT_ONCE'),1);self.assertTrue(r[2].strip())
 def test_rng_sequence_survives_queries_and_suffix(self):
  r=self.invoke("real :: x\ncall random_number(x)\nprint '(A)', 'RNG_PREFIX_ONCE'\nx\nx\n.vars\nx\ncall random_number(x)\nprint '(A)', 'RNG_SUFFIX_ONCE'\nx\nx\n.clear\n.quit\n")
  expected=self.batch("real :: x\ncall random_number(x)\nprint '(A)', 'RNG_PREFIX_ONCE'\nprint *, x\nprint *, x\nprint *, x\ncall random_number(x)\nprint '(A)', 'RNG_SUFFIX_ONCE'\nprint *, x\nprint *, x\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],expected);self.assertTrue(r[2].strip())
  self.assertEqual(r[1].count('RNG_PREFIX_ONCE'),1);self.assertEqual(r[1].count('RNG_SUFFIX_ONCE'),1)
 def test_explicit_run_resets_rng_then_preserves_query_state(self):
  r=self.invoke('real :: x\ncall random_number(x)\nx\ncall random_number(x)\nx\n.run\nx\nx\n.quit\n')
  baseline=self.batch('real :: x\ncall random_number(x)\nprint *, x\ncall random_number(x)\nprint *, x\n')
  lines=baseline.splitlines(keepends=True);self.assertEqual(len(lines),2);self.assertNotEqual(lines[0],lines[1])
  self.assertEqual(self.clean(r),baseline+lines[1]+lines[1])
 def test_invalid_query_preserves_committed_scalar(self):
  r=self.invoke('integer :: i\ni=17\ni\nmissing_name+1\ni\n.clear\n.quit\n')
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],self.batch('print *, 17\nprint *, 17\n'));self.assertTrue(r[2].strip())
 def test_invalid_query_does_not_execute_pending_prefix(self):
  r=self.invoke("integer :: i\ni=8\nprint '(A)', 'MUST_REMAIN_PENDING'\nmissing_name+1\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_rejected_call_query_does_not_execute_prefix(self):
  for query in ('random_number(x)','abs(x)'):
   with self.subTest(query=query):
    r=self.invoke("real :: x\nx=2.0\nprint '(A)', 'CALL_MUST_NOT_FLUSH'\n"+query+'\n.clear\n.quit\n')
    self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_frozen_declarations_do_not_reset_existing_state(self):
  r=self.invoke('integer :: i\ni=23\ni\ninteger :: late\ni\n.clear\n.quit\n')
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],self.batch('print *, 23\nprint *, 23\n'));self.assertTrue(r[2].strip())
 def test_runtime_failure_taints_until_clear(self):
  r=self.invoke("integer :: i,z\ni=5\nz=0\nprint '(A)', 'BEFORE_TAINT_ONCE'\ni\ni=1/z\ni\ni\n.clear\ninteger :: j\nj=31\nj\n.quit\n")
  expected=self.batch("print '(A)', 'BEFORE_TAINT_ONCE'\nprint *, 5\nprint *, 31\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],expected);self.assertEqual(r[1].count('BEFORE_TAINT_ONCE'),1);self.assertTrue(r[2].strip())
 def test_explicit_run_repeats_fresh_then_queries_do_not(self):
  r=self.invoke("integer :: i\ni=1\nprint '(A)', 'EXPLICIT_RUN_EFFECT'\ni\ni=i+1\ni\n.run\ni\ni\n.quit\n")
  expected=self.batch("print '(A)', 'EXPLICIT_RUN_EFFECT'\nprint *, 1\nprint *, 2\nprint '(A)', 'EXPLICIT_RUN_EFFECT'\nprint *, 2\nprint *, 2\n")
  self.assertEqual(self.clean(r),expected);self.assertEqual(r[1].count('EXPLICIT_RUN_EFFECT'),2)
 def test_explicit_run_seeds_resumable_session_once(self):
  r=self.invoke("integer :: i\ni=37\nprint '(A)', 'RUN_SEED_ONCE'\n.run\ni\ni+1\n.quit\n")
  expected=self.batch("print '(A)', 'RUN_SEED_ONCE'\nprint *, 37\nprint *, 38\n")
  self.assertEqual(self.clean(r),expected);self.assertEqual(r[1].count('RUN_SEED_ONCE'),1)
 def test_array_session_rejected_before_prefix_effects(self):
  r=self.invoke("integer :: a(2),i\ni=3\nprint '(A)', 'ARRAY_PREFIX_FORBIDDEN'\ni\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_initialized_decl_session_rejected_before_effects(self):
  r=self.invoke("integer :: i=3\nprint '(A)', 'INIT_PREFIX_FORBIDDEN'\ni\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_loop_fallback_run_is_not_replayed_by_query(self):
  r=self.invoke("integer :: i\ndo i=1,2\nprint '(A)', 'LOOP_FALLBACK'\nend do\n.run\ni\n.vars\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'LOOP_FALLBACK\nLOOP_FALLBACK\n');self.assertTrue(r[2].strip())
 def test_parameter_session_rejected_before_effects(self):
  r=self.invoke("integer, parameter :: i=3\nprint '(A)', 'PARAM_PREFIX_FORBIDDEN'\ni\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_unsupported_procedure_before_prefix_effects(self):
  r=self.invoke("integer :: i\ni=3\nprint '(A)', 'PROC_PREFIX_FORBIDDEN'\ncontains\nsubroutine inner()\nend subroutine\ni\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_saved_scalar_rejected_before_effects(self):
  r=self.invoke("integer, save :: i\ni=3\nprint '(A)', 'SAVE_PREFIX_FORBIDDEN'\ni\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_unsupported_loop_query_does_not_run_prefix(self):
  r=self.invoke("integer :: i\ni=0\nprint '(A)', 'CONTROL_PREFIX_FORBIDDEN'\ndo i=1,2\nend do\ni\n.clear\n.quit\n")
  self.assertEqual(r[0],0,repr(r));self.assertEqual(r[1],'');self.assertTrue(r[2].strip())
 def test_pending_source_eof_does_not_execute(self):
  r=self.invoke("integer :: i\ni=1\nprint '(A)', 'EOF_PENDING_FORBIDDEN'\n")
  self.assertEqual(self.clean(r),'')

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True);ap.add_argument('--report');a=ap.parse_args();CANDIDATE=Path(a.candidate).resolve(strict=True)
 if a.report and os.path.lexists(a.report):ap.error('report exists')
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();suite=unittest.defaultTestLoader.loadTestsFromTestCase(Session);r=unittest.TextTestRunner(verbosity=2).run(suite);after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful()and before==after
 if a.report:
  with open(a.report,'x')as f:json.dump(dict(status='passed'if ok else'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate=str(CANDIDATE),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),f,indent=2);f.write('\n')
 raise SystemExit(0 if ok else 1)
