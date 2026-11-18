#!/usr/bin/env python3
import argparse,hashlib,json,pathlib,subprocess,tempfile,unittest
CANDIDATE=None;RECORDS=[]
class LoopControl(unittest.TestCase):
 def invoke(self,source,defer=False,steps=None,batch=False):
  args=[str(CANDIDATE)] if batch else [str(CANDIDATE),'--repl','--nologo','--prompt','']+(['--defer-check'] if defer else [])+(['--max-steps',str(steps)] if steps else [])
  with tempfile.TemporaryDirectory() as d:p=subprocess.run(args,input=source,text=True,capture_output=True,cwd=d,timeout=20)
  RECORDS.append(dict(source=source,args=args,code=p.returncode,stdout=p.stdout,stderr=p.stderr));return p
 def clean(self,p):self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def oracle(self,body):return self.clean(self.invoke('program oracle\nimplicit none\n'+body+'end program oracle\n',batch=True))
 def compare(self,body,queries,defer=False):
  self.assertEqual(self.clean(self.invoke(body+'\n'.join(queries)+'\n.quit!\n',defer)),self.oracle(body+''.join('print *,'+q+'\n' for q in queries)))
 def test_while_basic_and_false(self):
  for limit in (0,3):
   for defer in (False,True):self.compare(f'integer :: n\nn=0\ndo while(n<{limit})\nn=n+1\nend do\n',['n','n'],defer)
 def test_bare_exit(self):
  for defer in (False,True):self.compare('integer :: n\nn=0\ndo\nn=n+1\nif(n==3) exit\nend do\n',['n','n'],defer)
 def test_counted_cycle(self):
  self.compare('integer :: i,n\nn=0\ndo i=1,3\nif(i==2) cycle\nn=n+i\nend do\n',['n','i'])
 def test_while_cycle(self):
  self.compare('integer :: n,s\nn=0\ns=0\ndo while(n<3)\nn=n+1\nif(n==2)cycle\ns=s+n\nend do\n',['n','s'])
 def test_named_outer_exit(self):
  body='integer :: i,n\nn=0\nouter: do i=1,3\ndo while(n<5)\nn=n+1\nif(n==2) exit outer\nend do\nend do outer\n'
  self.compare(body,['n','i'])
 def test_named_outer_cycle_releases_inner(self):
  body='integer :: i,j,n\nn=0\nouter: do i=1,3\ndo j=1,2\nn=n+1\ncycle outer\nend do\nend do outer\ndo j=1,2\nn=n+1\nend do\n'
  self.compare(body,['n','i','j'])
 def test_named_bare_and_named_while(self):
  body='integer :: n,s\nn=0\ns=0\nouter: do while(n<3)\nn=n+1\ninner: do\ns=s+1\nif(s==2)cycle outer\nexit inner\nend do inner\nend do outer\n'
  self.compare(body,['n','s'])
 def test_reduction_condition(self):
  self.compare('integer :: a(3)\na=0\ndo while(all(a<3))\na=a+1\nend do\n',['a','sum(a)'])
 def test_case_variants(self):
  for opener,closer in [('LOOP: DO WHILE(n<2)','END DO LOOP'),('LoOp: dO wHiLe(n<2)','EnDdO lOoP'),('LoOp: dO','EnD dO lOoP')]:
   p=self.invoke('integer :: n\nn=0\n'+opener+"\nn=n+1\nprint '(A)', 'MiXeD'\nif(n==2) EXIT LOOP\n"+closer+'\n.quit!\n');self.assertEqual(self.clean(p),'MiXeD\nMiXeD\n')
 def test_incomplete_no_effects(self):
  for opener in ('do','do while(.true.)','outer: do','outer: do while(.true.)'):
   p=self.invoke(opener+"\nprint '(A)', 'FORBIDDEN'\n.quit!\n");self.assertEqual(self.clean(p),'')
 def test_no_replay_queries_vars_and_later_loop(self):
  body="integer :: n\nn=0\ndo while(n<2)\nn=n+1\nprint '(A)', 'ONCE'\nend do\n"
  p=self.invoke(body+'n\n.vars\nn\ndo\nn=n+1\nexit\nend do\nn\n.quit!\n');s=self.clean(p);self.assertEqual(s.count('ONCE'),2);self.assertEqual(s.splitlines()[-1].strip(),'3')
 def test_rng_no_replay(self):
  body='integer :: n\nreal :: x\nn=0\ncall random_seed()\ndo while(n<2)\nn=n+1\ncall random_number(x)\nend do\n'
  tail='do\ncall random_number(x)\nexit\nend do\n'
  for defer in (False,True):self.assertEqual(self.clean(self.invoke(body+'x\nx\n'+tail+'x\nx\n.quit!\n',defer)),self.oracle(body+'print *,x\nprint *,x\n'+tail+'print *,x\nprint *,x\n'))
 def test_growth_after_named_while(self):
  p=self.invoke("integer :: n\nn=0\nouter: do while(n<2)\nn=n+1\nprint '(A)', 'ONCE'\nend do outer\nreal :: x\nx=3.0\nn\n.vars\n.quit!\n");s=self.clean(p);self.assertEqual(s.count('ONCE'),2);self.assertIn('n = 2',s);self.assertIn('x =',s)
 def test_false_condition_skips_undefined(self):
  self.assertEqual(self.clean(self.invoke('integer :: n,u\nn=1\ndo while(.false.)\nn=u\nend do\nn\n.quit!\n')).split(),['1'])
 def test_infinite_budget_taint(self):
  for opener in ('do','do while(.true.)'):
   body=opener+"\nprint '(A)', 'TICK'\nend do\n"
   baseline=self.invoke(body+'.clear\n.quit!\n',steps=25)
   p=self.invoke(body+'1\n.vars\n.clear\n.quit!\n',steps=25);self.assertEqual(p.returncode,0);self.assertIn('tainted',p.stderr);self.assertGreater(p.stdout.count('TICK'),0);self.assertEqual(p.stdout,baseline.stdout)
 def test_undefined_condition_taint(self):
  p=self.invoke('logical :: flag\ndo while(flag)\nprint *,1\nend do\n.vars\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertIn('tainted',p.stderr)
 def test_runtime_error_no_retry(self):
  p=self.invoke("integer :: n\nn=0\ndo\nprint '(A)', 'ONCE'\nn=1/n\nexit\nend do\nn\n.vars\n.clear\n.quit!\n");self.assertEqual(p.stdout,'ONCE\n');self.assertIn('tainted',p.stderr)
 def test_explicit_run_restarts(self):
  p=self.invoke("integer :: n\nn=0\ndo\nn=n+1\nprint '(A)', 'ONCE'\nexit\nend do\n.run\nn\n.quit!\n");self.assertEqual(self.clean(p).split(),['ONCE','ONCE','1'])
 def test_edited_loop_gate(self):
  p=self.invoke('integer :: n\nn=0\ndo while(n<2)\nn=n+1\nend do\n.rep 4 n=n+2\nn\n.run\nn\n.quit!\n');self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['2'])
 def test_bad_transfer_no_deferred_effect(self):
  for line in ('exit missing','cycle missing'):
   p=self.invoke("integer :: n\nn=0\nprint '(A)', 'FORBIDDEN'\ndo\n"+line+'\nend do\nn\n.clear\n.quit!\n',True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_invalid_query_no_pending_flush(self):
  p=self.invoke("integer :: n\nn=0\ndo\nprint '(A)', 'FORBIDDEN'\nexit\nend do\nunknown(n)\n.clear\n.quit!\n",True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(LoopControl));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
