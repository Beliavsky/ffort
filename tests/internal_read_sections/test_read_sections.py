#!/usr/bin/env python3
"""Internal list-directed READ rank-one destination section regressions."""
import argparse,json,subprocess,tempfile,unittest
from pathlib import Path
CANDIDATE=None
class ReadSections(unittest.TestCase):
 def invoke(self,body):
  with tempfile.TemporaryDirectory() as d:
   return subprocess.run([str(CANDIDATE)],input='program p\nimplicit none\n'+body+'\nend program p\n',capture_output=True,text=True,cwd=d,timeout=20)
 def good(self,body):
  p=self.invoke(body);self.assertEqual(p.returncode,0,p.stderr);self.assertEqual(p.stderr,'');return p.stdout.split()
 def test_prefix_variable(self):self.assertEqual(self.good('integer :: a(5),i,s\ncharacter(len=20) :: text\na=-9\ni=3\ntext="1 2 3"\nread(text,*,iostat=s)a(:i)\nprint *,s,a'),['0','1','2','3','-9','-9'])
 def test_stride_negative(self):self.assertEqual(self.good('integer :: a(-1:3),s\ncharacter(len=20) :: t\na=-9\nt="1 2 3"\nread(t,*,iostat=s)a(3:-1:-2)\nprint *,s,a'),['0','3','-9','2','-9','1'])
 def test_stride_positive(self):self.assertEqual(self.good('integer :: a(6),s,l,u,k\ncharacter(len=20) :: t\na=0\nl=2\nu=6\nk=2\nt="1 2 3"\nread(t,*,iostat=s)a(l:u:k)\nprint *,a'),['0','1','0','2','0','3'])
 def test_omitted_negative_empty(self):self.assertEqual(self.good('integer :: a(3),s\ncharacter(len=20) :: t\na=-9\nt="1 2 3"\nread(t,*,iostat=s)a(::-1)\nprint *,s,a'),['0','-9','-9','-9'])
 def test_empty_outside_bounds(self):self.assertEqual(self.good('integer :: a(3),s\ncharacter(len=20) :: t\na=-9\nt="1 2 3"\nread(t,*,iostat=s)a(10:9)\nprint *,s,a'),['0','-9','-9','-9'])
 def test_allocatable_real_kinds(self):
  for kind in [4,8]:
   s=self.good(f'real(kind={kind}),allocatable :: a(:)\ninteger :: i,s\ncharacter(len=20) :: t\nallocate(a(-1:3))\na=-9\ni=2\nt="1.5 2.5 3.5"\nread(t,*,iostat=s)a(0:i)\nprint *,s,a')
   self.assertEqual(int(s[0]),0);self.assertEqual([float(x) for x in s[1:]],[-9,1.5,2.5,3.5,-9])
 def test_integer8(self):self.assertEqual(self.good('integer(kind=8) :: a(3)\ninteger :: s\ncharacter(len=40) :: t\na=0\nt="2147483648 2147483649"\nread(t,*,iostat=s)a(1:2)\nprint *,s,a'),['0','2147483648','2147483649','0'])
 def test_character(self):self.assertEqual(self.good('character(len=4) :: a(3)\ncharacter(len=20) :: t\ninteger :: s\na="old"\nt="red,blue"\nread(t,*,iostat=s)a(2:3)\nprint *,s\nprint "(A)",a'),['0','old','red','blue'])
 def test_null_preserve(self):self.assertEqual(self.good('integer :: a(5),s\ncharacter(len=20) :: t\na=8\nt="1,,3"\nread(t,*,iostat=s)a(2:4)\nprint *,s,a'),['0','8','1','8','3','8'])
 def test_slash_preserve(self):self.assertEqual(self.good('integer :: a(5),s\ncharacter(len=20) :: t\na=8\nt="1 /"\nread(t,*,iostat=s)a(2:4)\nprint *,s,a'),['0','8','1','8','8','8'])
 def test_error_untouched(self):self.assertEqual(self.good('integer :: a(5),s\ncharacter(len=20) :: t\na=8\nt="1 bad 3"\nread(t,*,iostat=s)a(2:4)\nprint *,s>0,a(1),a(5)'),['T','8','8'])
 def test_eof_untouched(self):self.assertEqual(self.good('integer :: a(5),s\ncharacter(len=20) :: t\na=8\nt="1"\nread(t,*,iostat=s)a(2:4)\nprint *,s<0,a(1),a(5)'),['T','8','8'])
 def test_failure_selected_undefined(self):
  p=self.invoke('integer :: a(5),s\ncharacter(len=20) :: t\na=8\nt="1 bad"\nread(t,*,iostat=s)a(2:4)\nprint *,a(2)');self.assertNotEqual(p.returncode,0);self.assertIn('uninitialized',p.stderr)
 def test_utility_retry_pattern(self):
  s=self.good('real(kind=8),allocatable :: a(:)\ninteger :: i,s\ncharacter(len=30) :: t\nallocate(a(5))\nt="1.5 2.5 3.5"\ndo i=5,1,-1\nread(t,*,iostat=s)a(:i)\nif(s==0)exit\nend do\nprint *,s,i,a(:i)');self.assertEqual(s[:2],['0','3']);self.assertEqual([float(x) for x in s[2:]],[1.5,2.5,3.5])
 def test_no_iostat_success(self):self.assertEqual(self.good('integer :: a(3)\ncharacter(len=20) :: t\na=0\nt="1 2"\nread(t,*)a(1:2)\nprint *,a'),['1','2','0'])
 def test_no_iostat_failure(self):
  p=self.invoke('integer :: a(3)\ncharacter(len=20) :: t\nt="bad"\nread(t,*)a(1:2)');self.assertNotEqual(p.returncode,0);self.assertIn('invalid value',p.stderr)
 def test_bad_stride(self):
  p=self.invoke('integer :: a(3),k,s\ncharacter(len=20) :: t\na=0\nk=0\nt="1 2"\nread(t,*,iostat=s)a(1:2:k)');self.assertNotEqual(p.returncode,0);self.assertIn('stride',p.stderr)
 def test_exclusions(self):
  for item in ['a([1,2])','(a(1:2))','a(1:2),a(3:4)','a(:s)','s,a(:s)']:
   p=self.invoke('integer :: a(4),s\ncharacter(len=20) :: t\na=0\ns=2\nt="1 2"\nread(t,*,iostat=s)'+item);self.assertNotEqual(p.returncode,0,item)
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('--candidate',required=True);a.add_argument('--report');o=a.parse_args();CANDIDATE=Path(o.candidate).resolve(strict=True)
 r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(ReadSections))
 if o.report:Path(o.report).write_text(json.dumps(dict(status='passed' if r.wasSuccessful() else 'failed',tests=r.testsRun),indent=2)+'\n')
 raise SystemExit(not r.wasSuccessful())
