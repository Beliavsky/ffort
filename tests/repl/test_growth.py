#!/usr/bin/env python3
import argparse,hashlib,json,pathlib,subprocess,tempfile,unittest
CANDIDATE=None;RECORDS=[]
class Growth(unittest.TestCase):
 def invoke(self,source,defer=False,batch=False):
  args=[str(CANDIDATE)] if batch else [str(CANDIDATE),'--repl','--nologo','--prompt','']+(['--defer-check'] if defer else [])
  with tempfile.TemporaryDirectory() as d:p=subprocess.run(args,input=source,text=True,capture_output=True,cwd=d,timeout=20)
  RECORDS.append(dict(source=source,args=args,code=p.returncode,stdout=p.stdout,stderr=p.stderr));return p
 def clean(self,p):self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def oracle(self,body):return self.clean(self.invoke('program oracle\nimplicit none\n'+body+'end program oracle\n',batch=True))
 def test_three_types_and_repeated_growth(self):
  source='integer :: n\nn=7\nn\nreal :: x\nx=2.5\nlogical :: flag\nflag=.true.\ninteger :: k\nk=n+1\nn\nx\nflag\nk\n.quit!\n'
  for defer in (False,True):
   out=self.clean(self.invoke(source,defer)).split();self.assertEqual(out[:2],['7','7']);self.assertEqual(float(out[2]),2.5);self.assertEqual(out[3:],['T','8'])
 def test_old_arrays_character_and_undefined(self):
  s=self.clean(self.invoke("integer :: a(3),u\ncharacter(len=4) :: s\na=[1,2,3]\ns='AbCd'\ns\nreal :: fresh\na=a*2\na\ns\n.vars\n.quit!\n"));self.assertEqual(s.splitlines()[0].strip(),'AbCd');self.assertIn('2 4 6',' '.join(s.split()));self.assertIn('u = <undefined>',s);self.assertIn('fresh = <undefined>',s)
 def test_new_scalar_undefined(self):
  s=self.clean(self.invoke('integer :: n\nn=4\nreal :: x\n.vars\n.quit!\n'));self.assertIn('n = 4',s);self.assertIn('x = <undefined>',s)
 def test_empty_literal_session(self):
  self.assertEqual(self.clean(self.invoke('2+2\ninteger :: n\nn=5\nn\n.quit!\n')).split(),['4','5'])
 def test_comments_blank_declaration_only(self):
  s=self.clean(self.invoke('! spec comment\ninteger :: n\n\n.vars\n! trailing comment\nReAl :: Fresh ! KeEp CaSe\n.vars\n.list -n\n.quit!\n'));self.assertIn('Fresh ! KeEp CaSe',s);self.assertIn('fresh = <undefined>',s)
 def test_hoisted_source_exact(self):
  source="integer :: n\nn=7\nreal :: x ! MiXeD\n.list -n\n.quit!\n"
  self.assertEqual(self.clean(self.invoke(source)),'program repl_session\nimplicit none\ninteger :: n\nreal :: x ! MiXeD\nn=7\nend program repl_session\n')
 def test_prior_output_not_replayed(self):
  p=self.invoke("integer :: n\nn=1\nprint '(A)', 'ONCE'\nreal :: x\nx=2.0\nn\n.vars\nn\n.quit!\n");s=self.clean(p);self.assertEqual(s.count('ONCE'),1);self.assertEqual(s.splitlines()[-1].strip(),'1')
 def test_pending_print_stays_pending(self):
  p=self.invoke("integer :: n\nn=1\nn\nprint '(A)', 'PENDING'\nreal :: x\n.quit!\n",True);self.assertEqual(self.clean(p).split(),['1'])
 def test_pending_suffix_executes_once(self):
  p=self.invoke("integer :: n\nn=1\nn\nprint '(A)', 'PENDING'\nn=n+1\nreal :: x\nn\nn\n.quit!\n",True);self.assertEqual(self.clean(p).split(),['1','PENDING','2','2'])
 def test_rng_retention(self):
  pre='real :: x\ncall random_seed()\ncall random_number(x)\n';tail='call random_number(x)\n'
  expected=self.oracle('real :: x,y\ncall random_seed()\ncall random_number(x)\nprint *,x\nprint *,x\n'+tail+'print *,x\nprint *,x\n')
  for defer in (False,True):self.assertEqual(self.clean(self.invoke(pre+'x\nreal :: y\nx\n'+tail+'x\nx\n.quit!\n',defer)),expected)
 def test_completed_loops_and_if_preserved(self):
  s=self.clean(self.invoke('integer :: i,a(3)\na=0\ndo i=1,3\nif(i>0) a(i)=i*i\nend do\ninteger :: n\nn=sum(a)\na\nn\n.quit!\n'));self.assertEqual(s.split(),['1','4','9','14'])
 def test_first_executable_continued(self):
  s=self.clean(self.invoke('integer :: n\nn=1+ &\n& 2\nn\nreal :: x\nn\n.quit!\n'));self.assertEqual(s.split(),['3','3'])
 def test_bad_declarations_not_stored(self):
  for line in ('integer :: n','real :: n','integer(kind=4) :: fresh','integer :: fresh(2)','integer :: fresh=1','integer,save :: fresh','integer :: x,y','character(len=3) :: fresh','real fresh','integer :: fresh; print *,999'):
   p=self.invoke('integer :: n\nn=7\n'+line+'\nn\n.list -n\n.quit!\n');self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.splitlines()[0].strip(),'7');self.assertEqual(p.stdout.splitlines()[1:],['program repl_session','implicit none','integer :: n','n=7','end program repl_session'])
 def test_open_block_rejects_growth_without_corrupting(self):
  p=self.invoke('integer :: n\nn=1\nif(.true.) then\nreal :: x\nn=n+1\nend if\nn\n.quit!\n');self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['2'])
 def test_invalid_pending_source_rejects_growth(self):
  p=self.invoke('integer :: n\nn=1\nn=\nreal :: x\n.list -n\n.clear\n.quit!\n');self.assertTrue(p.stderr);self.assertNotIn('real :: x',p.stdout);self.assertIn('n=\n',p.stdout)
 def test_editor_gate_stays_closed(self):
  p=self.invoke('integer :: n\nn=1\n.rep 2 n=2\nreal :: x\nn\n.run\nreal :: x\nx=3.0\nn\n.quit!\n');self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertEqual(p.stdout.split(),['2'])
 def test_taint_gate(self):
  p=self.invoke('integer :: n\nn=1/0\nreal :: x\n.list -n\n.clear\ninteger :: n\nn=2\nreal :: x\nx=3.0\nn\n.quit!\n');self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertNotIn('real :: x',p.stdout);self.assertEqual(p.stdout.splitlines()[-1].strip(),'2')
 def test_nonresumable_gate(self):
  p=self.invoke('integer :: n\ncharacter(len=32) :: scratch\nn=0\nwrite(scratch,\"(I0)\") n\nn=1\n.run\nreal :: x\n.list -n\n.clear\n.quit!\n');self.assertTrue(p.stderr);self.assertNotIn('real :: x',p.stdout)
 def test_saved_source_is_standard_and_no_replay(self):
  p=self.invoke("integer :: n\nn=1\nprint '(A)', 'ONCE'\nreal :: x\nx=2.0\n.save grown.f90\n.clear\n.load grown.f90\nn\nx\n.quit!\n");s=self.clean(p);self.assertEqual(s.count('ONCE'),2);self.assertIn('Saved source to grown.f90',s)
 def test_spec_continuation_conservative_refusal(self):
  p=self.invoke('integer :: n, &\n& m\nn=1\nm=2\nreal :: x\nn+m\n.list -n\n.quit!\n');self.assertEqual(p.returncode,0);self.assertTrue(p.stderr);self.assertNotIn('real :: x',p.stdout);self.assertEqual(p.stdout.splitlines()[0].strip(),'3')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Growth));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
