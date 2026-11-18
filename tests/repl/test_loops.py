#!/usr/bin/env python3
import argparse,hashlib,json,pathlib,subprocess,tempfile,unittest
CANDIDATE=None;RECORDS=[]
class Loops(unittest.TestCase):
 def invoke(self,source,defer=False,steps=None,batch=False):
  args=[str(CANDIDATE)] if batch else [str(CANDIDATE),'--repl','--nologo','--prompt','']+(['--defer-check'] if defer else [])+(['--max-steps',str(steps)] if steps else [])
  with tempfile.TemporaryDirectory() as d:p=subprocess.run(args,input=source,text=True,capture_output=True,cwd=d,timeout=20)
  RECORDS.append(dict(source=source,args=args,code=p.returncode,stdout=p.stdout,stderr=p.stderr));return p
 def clean(self,p):self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def oracle(self,body):return self.clean(self.invoke('program oracle\nimplicit none\n'+body+'end program oracle\n',batch=True))
 def test_counts_and_final_index(self):
  for control in ('1,3','3,1,-1','2,8,2','3,1','1,3,-1'):
   for defer in (False,True):
    body='integer :: i,n\nn=0\ndo i='+control+'\nn=n+i\nend do\n'
    self.assertEqual(self.clean(self.invoke(body+'n\ni\nn\n.quit!\n',defer)),self.oracle(body+'print *,n\nprint *,i\nprint *,n\n'))
 def test_empty_body_and_integer8(self):
  body='integer(kind=8) :: i\ndo i=1_8,3_8\nend do\n'
  self.assertEqual(self.clean(self.invoke(body+'i\n.quit!\n')),self.oracle(body+'print *,i\n'))
 def test_bounds_frozen_at_entry(self):
  body='integer :: i,n,m,s\nn=3\ns=1\nm=0\ndo i=1,n,s\nn=1\ns=3\nm=m+i\nend do\n'
  self.assertEqual(self.clean(self.invoke(body+'m\ni\n.quit!\n')),self.oracle(body+'print *,m\nprint *,i\n'))
 def test_nested_array_and_if(self):
  body='integer :: i,j,a(2)\na=0\ndo i=1,2\ndo j=1,3\nif (j/=2) a(i)=a(i)+j\nend do\nend do\n'
  self.assertEqual(self.clean(self.invoke(body+'a\na\n.quit!\n')).split(),['4','4','4','4'])
 def test_closure_spellings(self):
  for close in ('end do','enddo','END DO','ENDDO','EnD dO','EnDdO'):
   p=self.invoke("integer :: i\ndo i=1,2\nprint '(A)', 'ONCE'\n"+close+'\n.quit!\n');self.assertEqual(self.clean(p),'ONCE\nONCE\n')
 def test_incomplete_no_effects(self):
  for tail in ('','do j=1,2\nprint *,j\nend do\n'):
   p=self.invoke("integer :: i,j\ndo i=1,2\nprint '(A)', 'FORBIDDEN'\n"+tail+'.quit!\n');self.assertEqual(self.clean(p),'')
 def test_queries_vars_no_replay(self):
  body="integer :: i,n\nn=0\ndo i=1,2\nn=n+1\nprint '(A)', 'BODY'\nend do\n"
  for defer in (False,True):
   p=self.invoke(body+'n\n.vars\nn\ndo i=1,2\nn=n+1\nend do\nn\n.quit!\n',defer);s=self.clean(p);self.assertEqual(s.count('BODY'),2);self.assertEqual(s.splitlines()[-1].strip(),'4');self.assertIn('n = 2',s)
 def test_rng_no_replay(self):
  body='integer :: i\nreal :: x\ncall random_seed()\ndo i=1,3\ncall random_number(x)\nend do\n'
  tail='do i=1,2\ncall random_number(x)\nend do\n'
  for defer in (False,True):
   expected=self.oracle(body+'print *,x\nprint *,x\n'+tail+'print *,x\nprint *,x\n')
   self.assertEqual(self.clean(self.invoke(body+'x\nx\n'+tail+'x\nx\n.quit!\n',defer)),expected)
 def test_skipped_body_undefined(self):
  self.assertEqual(self.clean(self.invoke('integer :: i,n,u\nn=5\ndo i=2,1\nn=u\nend do\nn\n.quit!\n')).split(),['5'])
 def test_errors_taint_without_replay(self):
  for control in ('1,2,0','u,2','2147483647,2147483647'):
   p=self.invoke('integer :: i,n,u\nn=7\ndo i='+control+'\nprint *,n\nend do\nn\n.vars\n.clear\ninteger :: k\nk=9\nk\n.quit!\n')
   self.assertEqual(p.returncode,0);self.assertIn('tainted',p.stderr);self.assertEqual(p.stdout.split()[-1],'9');self.assertLessEqual(p.stdout.split().count('7'),1)
 def test_step_budget_taint(self):
  p=self.invoke("integer :: i,n\nn=0\ndo i=1,1000\nn=n+1\nend do\nn\n.vars\n.clear\n.quit!\n",steps=30);self.assertIn('tainted',p.stderr);self.assertEqual(p.stdout,'')
 def test_bounds_failure_taint(self):
  p=self.invoke('integer :: i,a(2)\na=0\ndo i=1,3\na(i)=i\nend do\na\n.vars\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertIn('tainted',p.stderr)
 def test_explicit_run_restarts(self):
  body="integer :: i,n\nn=0\ndo i=1,2\nn=n+1\nprint '(A)', 'BODY'\nend do\n"
  p=self.invoke(body+'n\n.run\nn\n.quit!\n');self.assertEqual(self.clean(p).split(),['BODY','BODY','2','BODY','BODY','2'])
 def test_rejected_query_no_deferred_effect(self):
  p=self.invoke("integer :: i,n\nn=0\ndo i=1,2\nprint '(A)', 'FORBIDDEN'\nend do\nunknown(n)\n.clear\n.quit!\n",True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_edit_gate_and_run(self):
  source="integer :: i,n\nn=0\ndo i=1,2\nn=n+1\nend do\nn\n.rep 4 n=n+3\nn\n.run\nn\n.quit!\n"
  p=self.invoke(source);self.assertEqual(p.returncode,0);self.assertIn('source edited',p.stderr);self.assertEqual(p.stdout.split(),['2','6'])
 def test_saved_source_load_no_implicit_execution(self):
  source="integer :: i,n\nn=0\ndo i=1,2\nn=n+1\nprint '(A)', 'BODY'\nend do\n.save loop.f90\n.clear\n.load loop.f90\n.quit!\n"
  p=self.invoke(source);self.assertEqual(self.clean(p).splitlines(),['BODY','BODY','Saved source to loop.f90'])
 def test_if_skips_whole_loop(self):
  body='integer :: i,n\nn=3\nif (.false.) then\ndo i=1,2\nn=n+1\nend do\nendif\n'
  self.assertEqual(self.clean(self.invoke(body+'n\n.quit!\n')).split(),['3'])
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Loops));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
