#!/usr/bin/env python3
"""Independent unary-intrinsic session contracts; unittest assertions survive -O."""
import argparse, hashlib, json, math, pathlib, subprocess, tempfile, unittest
CANDIDATE=None
RECORDS=[]
class Intrinsics(unittest.TestCase):
 def invoke(self, source, defer=False, batch=False):
  argv=[str(CANDIDATE)] if batch else [str(CANDIDATE),'--repl','--nologo','--prompt','',*(['--defer-check'] if defer else [])]
  with tempfile.TemporaryDirectory() as d:
   p=subprocess.run(argv,input=source,text=True,capture_output=True,cwd=d,timeout=20)
  RECORDS.append(dict(argv=argv,source=source,code=p.returncode,stdout=p.stdout,stderr=p.stderr))
  return p
 def clean(self,p):
  self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def oracle(self,body):return self.clean(self.invoke('program oracle\nimplicit none\n'+body+'end program oracle\n',batch=True))
 def test_seven_intrinsics_kind4_and_kind8(self):
  for suffix in ('','_8'):
   for name,arg,expected in [('abs','-2.5',2.5),('sqrt','4.0',2),('sin','0.5',math.sin(.5)),('cos','0.5',math.cos(.5)),('exp','1.0',math.e),('log','2.0',math.log(2)),('log10','100.0',2)]:
    q=f'{name}({arg}{suffix})'
    with self.subTest(query=q):
     out=self.clean(self.invoke(q+'\n.quit!\n'));self.assertEqual(out,self.oracle('print *, '+q+'\n'));self.assertAlmostEqual(float(out),expected,places=6 if not suffix else 13)
 def test_seven_intrinsics_variable_arguments(self):
  for kind in (4,8):
   for name,arg in [('abs','-2.5'),('sqrt','4.0'),('sin','0.5'),('cos','0.5'),('exp','1.0'),('log','2.0'),('log10','100.0')]:
    body=f'real(kind={kind}) :: x\nx={arg}_{kind}\n'
    for defer in (False,True):
     with self.subTest(name=name,kind=kind,defer=defer):
      out=self.clean(self.invoke(body+name+'(x)\n'+name+'(x)\n.quit!\n',defer))
      self.assertEqual(out,self.oracle(body+'print *, '+name+'(x)\nprint *, '+name+'(x)\n'))
 def test_integer_abs_kinds(self):
  for q in ('abs(-7)','abs(-2147483649_8)'):
   with self.subTest(query=q):self.assertEqual(self.clean(self.invoke(q+'\n.quit!\n')),self.oracle('print *, '+q+'\n'))
 def test_nested_intrinsics(self):
  for q in ('sqrt(abs(-9.0))','log(exp(sin(0.25_8)))','cos(sqrt(abs(-4.0_8)))','abs(-abs(-7))'):
   with self.subTest(query=q):self.assertEqual(self.clean(self.invoke(q+'\n.quit!\n')),self.oracle('print *, '+q+'\n'))
 def test_mixed_kind_arithmetic(self):
  q='sqrt(4.0)+log(exp(1.0_8))+abs(-3)'
  self.assertEqual(self.clean(self.invoke(q+'\n.quit!\n')),self.oracle('print *, '+q+'\n'))
 def test_assignment_print_and_vars(self):
  source='real(kind=8) :: x\nx=sqrt(abs(-9.0_8))\nprint *, log10(100.0_8)\nx\n.vars\n.quit!\n'
  for defer in (False,True):
   with self.subTest(defer=defer):
    lines=self.clean(self.invoke(source,defer)).splitlines();self.assertEqual(len(lines),3);self.assertEqual(float(lines[0]),2);self.assertEqual(float(lines[1]),3);self.assertEqual(float(lines[2].split('=')[1]),3)
 def test_immediate_assignment_print_without_flush_command(self):
  self.assertEqual(self.clean(self.invoke('real :: x\nx=sqrt(4.0)\nprint *, x\n.quit!\n')),self.oracle('print *, sqrt(4.0)\n'))
 def test_deferred_assignment_print_stays_pending(self):
  self.assertEqual(self.clean(self.invoke('real :: x\nx=sqrt(4.0)\nprint *, x\n.quit!\n',True)),'')
 def test_queries_no_replay_both_modes(self):
  source="real :: x\nx=4.0\nprint '(A)', 'ONCE'\nsqrt(x)\nsqrt(x)\nx=x+5.0\nsqrt(x)\n.quit!\n"
  expected='ONCE\n'+self.oracle('print *, 2.0\nprint *, 2.0\nprint *, 3.0\n')
  for defer in (False,True):
   with self.subTest(defer=defer):self.assertEqual(self.clean(self.invoke(source,defer)),expected)
 def test_rng_not_advanced_by_intrinsic_queries(self):
  for defer in (False,True):
   source='real :: x\ncall random_seed()\ncall random_number(x)\nabs(x)\nsqrt(x*x)\nx\ncall random_number(x)\nabs(x)\nx\n.quit!\n'
   body='real :: x\ncall random_seed()\ncall random_number(x)\nprint *, abs(x)\nprint *, sqrt(x*x)\nprint *, x\ncall random_number(x)\nprint *, abs(x)\nprint *, x\n'
   with self.subTest(defer=defer):self.assertEqual(self.clean(self.invoke(source,defer)),self.oracle(body))
 def test_query_domain_failure_taints_then_clear_recovers(self):
  for q in ('sqrt(x)','log(x)','log10(x)'):
   for defer in (False,True):
    with self.subTest(query=q,defer=defer):
     p=self.invoke("real :: x\nx=-1.0\nprint '(A)', 'ONCE'\n"+q+'\nx\nx\n.clear\nsqrt(4.0)\n.quit!\n',defer)
     self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stdout,'ONCE\n'+self.oracle('print *, 2.0\n'));self.assertIn('tainted',p.stderr.lower())
 def test_log_zero_domain_failure(self):
  for q in ('log(0.0)','log10(0.0_8)'):
   with self.subTest(query=q):
    p=self.invoke(q+'\n.clear\n.quit!\n');self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout,'')
 def test_exp_overflow_diagnostic_and_recovery(self):
  for kind in (4,8):
   p=self.invoke(f'real(kind={kind}) :: x\nx=1000.0_{kind}\nexp(x)\n.clear\nsqrt(4.0)\n.quit!\n')
   self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout,self.oracle('print *, 2.0\n'))
 def test_assignment_domain_failure_is_not_retried(self):
  p=self.invoke("real :: x\nx=-1.0\nprint '(A)', 'ONCE'\nx=sqrt(x)\n.vars\n.vars\n.clear\n.quit!\n")
  self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'ONCE\n');self.assertIn('tainted',p.stderr.lower())
 def test_unsupported_calls_reject_before_pending_flush(self):
  for q in ('tan(x)','erfc(x)','dble(x)','kind(x)','random_number(x)','user_function(x)','abs(x,x)','sqrt()','abs(.true.)','sqrt(4)'):
   with self.subTest(query=q):
    p=self.invoke("real :: x\nx=2.0\nprint '(A)', 'MUST_NOT_RUN'\n"+q+'\n.clear\n.quit!\n',True)
    self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_rejected_calls_preserve_committed_state(self):
  for q in ('tan(x)','user_function(x)','sqrt(x,x)'):
   with self.subTest(query=q):
    p=self.invoke('real :: x\nx=9.0\nsqrt(x)\n'+q+'\nsqrt(x)\n.clear\n.quit!\n')
    self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,self.oracle('print *, 3.0\nprint *, 3.0\n'));self.assertTrue(p.stderr)
 def test_intrinsic_query_injection_rejected_preflush(self):
  for q in ('sqrt(x)), 99 ! splice','sqrt(x); print *, 99','abs(x), 99','sqrt(user_function(x))','sqrt(tan(x))'):
   with self.subTest(query=q):
    p=self.invoke("real :: x\nx=4.0\nprint '(A)', 'MUST_NOT_RUN'\n"+q+'\n.clear\n.quit!\n',True)
    self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_unsupported_specification_intrinsic_prevents_pending_effects(self):
  for declaration in ('integer(kind=kind(1)) :: n','character(len=int(3.0)) :: s','real(kind=selected_real_kind(6)) :: x'):
   with self.subTest(declaration=declaration):
    p=self.invoke(declaration+"\nprint '(A)', 'MUST_NOT_RUN'\nsqrt(4.0)\n.clear\n.quit!\n",True)
    self.assertEqual(p.returncode,0);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_query_not_saved_in_source(self):
  p=self.invoke('real :: x\nx=4.0\nsqrt(x)\n.list\n.quit!\n');out=self.clean(p)
  self.assertNotIn('sqrt',out);self.assertIn('x=4.0',out)
 def test_explicit_run_repeats_intentionally(self):
  p=self.invoke('real :: x\nx=sqrt(9.0)\nprint *, x\n.run\nsqrt(x*x)\n.quit!\n')
  self.assertEqual(self.clean(p),self.oracle('print *, 3.0\nprint *, 3.0\nprint *, 3.0\n'))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Intrinsics));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
