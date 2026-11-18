import subprocess,pathlib,tempfile,json,hashlib,math,argparse
P=argparse.ArgumentParser();P.add_argument('--gnu-only',action='store_true');opts=P.parse_args()
R=pathlib.Path(__file__).resolve().parents[1];C=R/'057-read-sections-work/build/gfortran_A86CEF2075723C1E/app/fortfront-interpreter';G=R.parent/'scifort-verification/toolchain/bin/gfortran'
cases=[]
def add(name,decl,setup,text,target,out='print *, ios==0\nprint *, a'):
 cases.append((name,decl,setup,text,target,out))
for target in ['a(2:4)','a(:3)','a(3:)','a(::2)','a(5:1:-2)','a(::-1)']:
 add(target,'integer :: a(5),ios','a=-9','1 2 3 4 5',target)
add('dynamic bounds','integer :: a(5),ios,i,j,k','a=-9\ni=2\nj=4\nk=1','7 8 9','a(i:j:k)')
add('negative lower','integer :: a(-3:1),ios','a=-9','4 5 6','a(-2:0)')
add('integer8','integer(8) :: a(5)\ninteger :: ios','a=-9_8','2147483648 2147483649','a(2:3)')
add('real4','real :: a(5)\ninteger :: ios','a=-9.0','1.5 2.5 3.5','a(2:4)')
add('real8','real(8) :: a(5)\ninteger :: ios','a=-9.0_8','1.5d0 2.5d0 3.5d0','a(2:4)')
add('nulls','integer :: a(5),ios','a=-9',',2,,','a(2:4)')
add('repeats','integer :: a(5),ios','a=-9','3*7','a(2:4)')
add('repeat null','integer :: a(5),ios','a=-9','2*,8','a(2:4)')
add('slash','integer :: a(5),ios','a=-9','1 /','a(2:4)')
add('empty target','integer :: a(5),ios','a=-9','','a(4:3)')
add('empty negative stride','integer :: a(5),ios','a=-9','','a(2:4:-1)')
add('empty outbounds','integer :: a(5),ios','a=-9','','a(10:9)')
add('empty base','integer :: a(4:3),ios','','','a(:)','print *, ios==0\nprint *, size(a)')
add('short input untouched','integer :: a(5),ios','a=-9','1','a(2:4)','print *, ios<0\nprint *, a(1),a(5)')
add('bad conversion untouched','integer :: a(5),ios','a=-9','1 bad 3','a(2:4)','print *, ios>0\nprint *, a(1),a(5)')
add('reverse bad untouched','integer :: a(5),ios','a=-9','1 bad 3','a(4:2:-1)','print *, ios>0\nprint *, a(1),a(5)')
add('following scalar','integer :: a(5),ios,b','a=-9\nb=-8','1 2 3 4','a(2:4),b','print *, ios==0\nprint *, a,b')
for target in ['a(5:1:-1)','a(:1:-1)','a(5::-1)','a(1:6:2)','a(5:0:-2)']:
 add('endpoint '+target,'integer :: a(5),ios','a=-9','1 2 3 4 5',target)
add('nonunit reverse','integer :: a(-3:1),ios','a=-9','1 2 3 4 5','a(1:-3:-1)')
add('nonunit omitted negative','integer :: a(-3:1),ios','a=-9','','a(::-1)')
add('fixed character','character(8) :: a(5)\ninteger :: ios',"a='old'","red green blue",'a(2:4)')
add('allocatable character','character(100),allocatable :: a(:)\ninteger :: ios',"allocate(a(5))\na='old'","red green blue",'a(2:4)')
results=[]
def eq(a,b):
 if len(a)!=len(b):return False
 for l,r in zip(a,b):
  if l==r:continue
  try:
   if not math.isclose(float(l.replace('D','E')),float(r.replace('D','E')),rel_tol=2e-6,abs_tol=2e-7):return False
  except ValueError:return False
 return True
with tempfile.TemporaryDirectory() as td:
 d=pathlib.Path(td)
 for name,decl,setup,text,target,out in cases:
  p=d/'p.f90';exe=d/'p';src='program p\nimplicit none\ncharacter(80) :: text\n'+decl+'\n'+setup+'\ntext="'+text+'"\nread(text,*,iostat=ios) '+target+'\n'+out+'\nend program\n';p.write_text(src)
  cc=subprocess.run([str(G),str(p),'-fcheck=all','-o',str(exe)],capture_output=True,text=True,timeout=30)
  if cc.returncode:results.append(dict(name=name,passed=False,stage='gnu_compile',stderr=cc.stderr));continue
  o=subprocess.run([str(exe)],capture_output=True,text=True,timeout=10)
  if opts.gnu_only:results.append(dict(name=name,passed=o.returncode==0,expected=o.stdout.split(),stderr=o.stderr,source=src));continue
  q=subprocess.run([str(C),str(p)],capture_output=True,text=True,timeout=15)
  results.append(dict(name=name,passed=o.returncode==0 and q.returncode==0 and not q.stderr and eq(o.stdout.split(),q.stdout.split()),expected=o.stdout.split(),actual=q.stdout.split(),stderr=q.stderr,returncode=q.returncode))
r=dict(status='passed' if all(x['passed'] for x in results) else 'failed',tests=len(results),mode='gnu-only' if opts.gnu_only else 'differential',results=results)
if not opts.gnu_only:r['candidate_sha256']=hashlib.sha256(C.read_bytes()).hexdigest()
path=R/'057-read-sections-evidence'/('gnu-read-sections.json' if opts.gnu_only else 'independent-read-sections-oracle.json');path.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2));raise SystemExit(r['status']!='passed')
