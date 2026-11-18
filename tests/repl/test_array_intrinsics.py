#!/usr/bin/env python3
"""Rank-one elemental math and metadata-only inquiries without replay."""
import argparse,json,subprocess,tempfile,unittest
from pathlib import Path
CANDIDATE=None
class ArrayIntrinsics(unittest.TestCase):
 def invoke(self,text,defer=False,batch=False,steps=None):
  args=[str(CANDIDATE)]
  if not batch:args+=['--repl','--nologo','--prompt','']+(['--defer-check'] if defer else [])
  if steps:args+=['--max-steps',str(steps)]
  with tempfile.TemporaryDirectory() as d:return subprocess.run(args,input=text,text=True,capture_output=True,cwd=d,timeout=20)
 def clean(self,p):self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def compare(self,body,queries,defer=False):
  want=self.clean(self.invoke('program p\nimplicit none\n'+body+''.join('print *,'+q+'\n' for q in queries)+'end program\n',batch=True))
  got=self.clean(self.invoke(body+'\n'.join(queries)+'\n.quit!\n',defer));self.assertEqual(got,want);return got
 def test_integer_abs_kinds(self):
  for kind in [4,8]:self.compare(f'integer(kind={kind}) :: a(-1:1)\na=[-3_{kind},0_{kind},2_{kind}]\n',['abs(a)','abs(-abs(a))'])
 def test_real_seven_kinds(self):
  for kind in [4,8]:
   body=f'real(kind={kind}) :: a(3)\na=[0.5_{kind},1.0_{kind},2.0_{kind}]\n'
   self.compare(body,[f'{name}(a)' for name in ['abs','sqrt','sin','cos','exp','log','log10']])
 def test_nested_math(self):self.compare('real :: a(2)\na=[-1.0,2.0]\n',['sqrt(abs(a))','sin(cos(a))','log(exp(a))'])
 def test_constructor_math(self):self.compare('', ['abs([-1,2,-3])','sqrt([1.0,4.0])'])
 def test_math_assignment_alias(self):self.compare('real :: a(-1:1),b(3)\na=[1.0,4.0,9.0]\nb=sqrt(a)\na=sqrt(a)+b\n',['a','b'])
 def test_math_reductions_control(self):self.compare('integer :: a(3),i,n\na=[-1,2,-3]\nn=0\ndo i=1,2\nif(sum(abs(a))==6) n=n+1\nend do\n',['n','sum(abs(a))'])
 def test_inquiry_nonunit(self):self.compare('integer :: a(-2:2)\n',['size(a)','size(a,1)','lbound(a)','ubound(a)','lbound(a,1)','ubound(a,1)'])
 def test_inquiry_keywords(self):self.compare('integer :: a(-2:2)\n',['size(array=a,dim=1)','lbound(dim=1,array=a)','ubound(array=a,dim=1_8)'])
 def test_inquiry_parenthesized_expression(self):self.compare('integer :: a(-2:2)\n',['lbound((a))','ubound((a))','lbound(a+1)','ubound(a+1)','size(abs(a))'])
 def test_inquiry_empty(self):self.compare('real :: a(5:2)\n',['size(a)','lbound(a)','ubound(a)','lbound(a,1)','ubound(a,1)','size(sqrt(a))'])
 def test_elemental_empty(self):self.compare('real :: a(2:1)\n',[f'{name}(a)' for name in ['abs','sqrt','sin','cos','exp','log','log10']])
 def test_inquiries_undefined_preserve(self):
  s=self.clean(self.invoke('integer :: a(2)\na(1)=8\nsize(a)\nlbound(a)\nubound(a)\n.vars a\n.quit!\n'));self.assertIn('<1/2 defined>',s);self.assertIn('a(2) = <undefined>',s)
 def test_inquiry_results_assignment(self):self.compare('integer :: a(-3:-1),b(1),n\nb=lbound(a)\nn=ubound(a,1)\n',['b','n'])
 def test_dynamic_dim(self):self.compare('integer(kind=8) :: d\ninteger :: a(4:6)\nd=1_8\n',['size(a,d)','lbound(a,d)','ubound(a,d)'])
 def test_invalid_dim_taints(self):
  for q in ['size(a,d)','lbound(a,d)','ubound(a,d)']:
   p=self.invoke('integer :: a(2),d\nd=2\n'+q+'\n.vars\n.clear\n.quit!\n');self.assertTrue(p.stderr);self.assertIn('tainted',p.stderr);self.assertEqual(p.stdout,'')
 def test_undefined_dim_taints(self):
  p=self.invoke('integer :: a(2),d\nsize(a,d)\n.vars\n.clear\n.quit!\n');self.assertTrue(p.stderr);self.assertEqual(p.stdout,'')
 def test_elemental_undefined_taints(self):
  p=self.invoke('real :: a(2)\na(1)=4.0\nsqrt(a)\n.vars\n.clear\n.quit!\n');self.assertTrue(p.stderr);self.assertIn('tainted',p.stderr)
 def test_domain_taints_no_retry(self):
  for q in ['sqrt(a)','log(a)','log10(a)']:
   p=self.invoke("real :: a(2)\na=[1.0,-1.0]\nprint '(A)', 'ONCE'\n"+q+'\n.vars\n.clear\n.quit!\n');self.assertEqual(p.stdout.count('ONCE'),1);self.assertIn('tainted',p.stderr)
 def test_overflow_taints(self):
  for body,q in [('real :: a(1)\na=1000.0\n','exp(a)'),('integer :: a(1)\na=-2147483647-1\n','abs(a)')]:
   p=self.invoke(body+q+'\n.vars\n.clear\n.quit!\n');self.assertIn('tainted',p.stderr)
 def test_rejected_kinds_no_pending(self):
  for q in ['lbound(a,kind=4)','ubound(a,kind=8)','lbound(a,1,4)','tan(a)','sqrt(a,a)']:
   p=self.invoke("real :: a(2)\na=1.0\nprint '(A)', 'FORBIDDEN'\n"+q+'\n.clear\n.quit!\n',True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_no_replay_pending(self):
  s=self.clean(self.invoke("real :: a(2)\na=4.0\nprint '(A)', 'ONCE'\nsqrt(a)\nsize(a)\nsqrt(a)\n.vars a\n.quit!\n",True));self.assertEqual(s.count('ONCE'),1)
 def test_inquiry_does_not_evaluate_domain(self):self.compare('real :: a(2)\na=-1.0\n',['size(sqrt(a))','lbound(log(a))','ubound(log10(a))'])
 def test_source_unchanged(self):
  s=self.clean(self.invoke('real :: a(2)\na=4.0\nsqrt(a)\nlbound(a)\n.list -n\n.quit!\n'));self.assertIn('real :: a(2)\na=4.0\nend program',s)
 def test_keyword_queries_not_stored(self):
  s=self.clean(self.invoke('integer :: a(2)\nsize(array=a,dim=1)\nlbound(dim=1,array=a)\n.list -n\n.quit!\n'));self.assertIn('integer :: a(2)\nend program',s);self.assertNotIn('array=a',s)
 def test_indexed_assignment_remains_source(self):
  s=self.clean(self.invoke('integer :: a(2)\na=0\na(size(a))=8\na\n.list -n\n.quit!\n'));self.assertIn('a(size(a))=8',s);self.assertEqual(s.splitlines()[0].split(),['0','8'])
 def test_constant_bad_dim_preserves_session(self):
  p=self.invoke('integer :: a(2)\na=3\nlbound(a,2)\na\n.quit!\n');self.assertTrue(p.stderr);self.assertNotIn('tainted',p.stderr);self.assertEqual(p.stdout.split(),['3','3'])
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('--candidate',required=True);a.add_argument('--report');o=a.parse_args();CANDIDATE=Path(o.candidate).resolve(strict=True)
 r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(ArrayIntrinsics))
 if o.report:Path(o.report).write_text(json.dumps(dict(status='passed' if r.wasSuccessful() else 'failed',tests=r.testsRun),indent=2)+'\n')
 raise SystemExit(not r.wasSuccessful())
