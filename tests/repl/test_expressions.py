#!/usr/bin/env python3
import argparse,hashlib,json,pathlib,subprocess,tempfile,unittest
CANDIDATE=None;RECORDS=[]
class Expressions(unittest.TestCase):
 def invoke(self,source,defer=False,steps=None,batch=False):
  args=[str(CANDIDATE)] if batch else [str(CANDIDATE),'--repl','--nologo','--prompt','']+(['--defer-check'] if defer else [])+(['--max-steps',str(steps)] if steps else [])
  with tempfile.TemporaryDirectory() as d:p=subprocess.run(args,input=source,text=True,capture_output=True,cwd=d,timeout=20)
  RECORDS.append(dict(source=source,args=args,code=p.returncode,stdout=p.stdout,stderr=p.stderr));return p
 def clean(self,p):self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout
 def oracle(self,body):return self.clean(self.invoke('program oracle\nimplicit none\n'+body+'end program oracle\n',batch=True))
 def compare(self,body,queries,defer=False):
  expected=self.oracle(body+''.join('print *,'+q+'\n' for q in queries));actual=self.clean(self.invoke(body+'\n'.join(queries)+'\n.quit!\n',defer));self.assertEqual(actual,expected)
 def test_converted_scalar_broadcasts(self):
  for body in ('real :: a(2)\na=1\n','integer :: a(2)\na=1.5\n','real(kind=8) :: a(2)\na=2_8\n','integer(kind=8) :: a(2)\na=2.75_8\n'):
   self.compare(body,['a','a'])
 def test_empty_reduction_broadcasts(self):
  for decl in ('integer','real','real(kind=8)'):
   body=decl+' :: a(2:1),b(2)\na=1\nb=product(a)\n'
   self.compare(body,['b','sum(a)','minval(a)','maxval(a)'])
 def test_constructor_types(self):
  for decl,value in [('integer','1,2,3'),('integer(kind=8)','1_8,2_8,3_8'),('real','1.0,2.0,3.0'),('real(kind=8)','1.0_8,2.0_8,3.0_8'),('logical','.true.,.false.,.true.')]:
   for defer in (False,True):
    with self.subTest(decl=decl,defer=defer):self.compare(decl+' :: a(3)\na=['+value+']\n',['a','a'],defer)
 def test_constructor_scalar_expressions(self):
  self.compare('integer :: n,a(3)\nn=4\na=2\na=[n,a(2)+n,abs(-n)]\n',['a','sum(a)'])
 def test_copy_lower_bounds_and_alias(self):
  self.compare('integer :: a(-1:1),b(3:5)\na=[1,2,3]\nb=a\na=a+2*b\nb=b+b\n',['a','b','a+b'])
 def test_scalar_expansion_both_sides(self):
  body='integer :: a(3)\na=[2,4,8]\n'
  self.compare(body,['a+2','2+a','a-2','10-a','a*2','2*a','a/2','16/a','-a','+a'])
 def test_real_arithmetic(self):
  self.compare('real(kind=8) :: a(2),b(2)\na=[1.5_8,2.5_8]\nb=[0.5_8,1.5_8]\n',['a+b','a-b','a*b','a/b','sum(a)','product(b)','minval(a)','maxval(b)'])
 def test_numeric_comparisons(self):
  self.compare('integer :: a(3),b(3)\na=[1,2,3]\nb=[3,2,1]\n',['a==b','a/=b','a<b','a<=b','a>b','a>=b','2<a','a<=2'])
 def test_logical_operations(self):
  self.compare('logical :: a(3),b(3)\na=[.true.,.false.,.true.]\nb=[.false.,.false.,.true.]\n',['.not.a','a.and.b','a.or.b','a.eqv.b','a.neqv.b','a.and..true.','.false..or.a'])
 def test_reductions(self):
  self.compare('integer(kind=8) :: a(3)\nlogical :: b(3)\na=[2_8,3_8,4_8]\nb=[.true.,.false.,.true.]\n',['sum(a)','product(a)','minval(a)','maxval(a)','all(b)','any(b)','count(b)','sum(a)+maxval(a)'])
 def test_reduction_assignment_if_loop(self):
  body='integer :: i,n,a(3)\na=[1,2,3]\nn=sum(a)\nif (all(a>0)) then\ndo i=1,2\na=a+1\nend do\nendif\n'
  self.compare(body,['n','a','sum(a)','count(a>3)'])
 def test_empty_arrays(self):
  body='integer :: a(2:1),b(2:1)\nlogical :: c(2:1)\na=3\nb=a+a\nc=.true.\n'
  self.compare(body,['a','b','sum(a)','product(a)','minval(a)','maxval(a)','all(c)','any(c)','count(c)'])
 def test_no_print_rng_replay(self):
  body="integer :: a(3)\nreal :: x\na=[1,2,3]\ncall random_seed()\ncall random_number(x)\nprint '(A)', 'ONCE'\n"
  self.compare(body,['sum(a)','sum(a)','x','x'],True)
 def test_vars_array_result(self):
  p=self.invoke('integer :: a(3)\na=[1,2,3]\na=a+2\n.vars\n.quit!\n');s=self.clean(p);self.assertIn('<3/3 defined>',s);self.assertIn('a(1) = 3',s);self.assertIn('a(3) = 5',s)
 def test_constructor_limit(self):
  def source(n):
   lines=['integer :: a('+str(n)+')']
   for start in range(0,n,32):
    last=start+32>=n
    lines.append(('a=[' if start==0 else '& ')+','.join(['1']*min(32,n-start))+(']' if last else ', &'))
   return ''.join('.ins '+str(i+1)+' '+line+'\n' for i,line in enumerate(lines))
  self.assertEqual(self.clean(self.invoke(source(256)+'sum(a)\n.quit!\n')).split(),['256'])
  p=self.invoke(source(257)+'sum(a)\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_rejected_constructor_forms(self):
  for expr in ('[integer::1,2,3]','[integer::]','[[1,2,3]]','[b]','[(i,i=1,3)]'):
   p=self.invoke("integer :: a(3),b(3),i\nb=1\nprint '(A)', 'FORBIDDEN'\na="+expr+'\n.vars\n.clear\n.quit!\n',True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_rejected_mixed_kind_no_pending_effects(self):
  for expr in ('a+1.0','a+1_8'):
   p=self.invoke("integer :: a(2)\na=1\nprint '(A)', 'FORBIDDEN'\n"+expr+'\n.clear\n.quit!\n',True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_rejected_sections_masks_and_array_calls(self):
  for expr in ('a(1:2)','sum(a,mask=a>0)','sum(a,dim=1)','int(a)','a**2'):
   p=self.invoke("integer :: a(3)\na=1\nprint '(A)', 'FORBIDDEN'\nprint *,"+expr+'\n.vars\n.clear\n.quit!\n',True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_rejected_shape_no_pending_effects(self):
  p=self.invoke("integer :: a(2),b(3)\na=1\nb=2\nprint '(A)', 'FORBIDDEN'\na+b\n.clear\n.quit!\n",True);self.assertEqual(p.stdout,'');self.assertTrue(p.stderr)
 def test_undefined_reduction_taint(self):
  p=self.invoke('integer :: a(3)\na(1)=1\nsum(a)\n.vars\n.clear\ninteger :: n\nn=9\nn\n.quit!\n');self.assertEqual(p.stdout.split(),['9']);self.assertIn('tainted',p.stderr)
 def test_runtime_arithmetic_failure_taint(self):
  for expr in ('a+a','a/(a-a)'):
   p=self.invoke('integer :: a(2)\na=2147483647\n'+expr+'\n.vars\n.clear\n.quit!\n');self.assertEqual(p.stdout,'');self.assertIn('tainted',p.stderr)
 def test_step_budget_taint(self):
  p=self.invoke('integer :: a(1000)\na=1\nsum(a+a)\n.vars\n.clear\n.quit!\n',steps=30);self.assertEqual(p.stdout,'');self.assertIn('tainted',p.stderr)
 def test_assignment_failure_no_retry(self):
  p=self.invoke("integer :: a(2),n\na=1\nprint '(A)', 'ONCE'\na=[n,2]\na\n.vars\n.clear\n.quit!\n");self.assertEqual(p.stdout.split(),['ONCE']);self.assertIn('tainted',p.stderr)
 def test_explicit_run_resumable(self):
  body='integer :: a(3)\na=[1,2,3]\na=a+1\n.run\n'
  self.assertEqual(self.clean(self.invoke(body+'a\nsum(a)\n.quit!\n')).split(),['2','3','4','9'])
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--report',required=True);a=p.parse_args();CANDIDATE=pathlib.Path(a.candidate).resolve(strict=True)
 before=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Expressions));after=hashlib.sha256(CANDIDATE.read_bytes()).hexdigest();ok=r.wasSuccessful() and before==after
 pathlib.Path(a.report).write_text(json.dumps(dict(status='passed' if ok else 'failed',tests=r.testsRun,failures=len(r.failures),errors=len(r.errors),candidate_sha256=before,candidate_after_sha256=after,records=RECORDS),indent=2)+'\n');raise SystemExit(0 if ok else 1)
