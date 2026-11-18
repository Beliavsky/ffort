import subprocess,pathlib,tempfile,json,hashlib
R=pathlib.Path(__file__).resolve().parents[1];C=R/'057-read-sections-work/build/gfortran_A86CEF2075723C1E/app/fortfront-interpreter';results=[]
def run(name,decl,body,check):
 src='program p\nimplicit none\ncharacter(80) :: text\n'+decl+'\n'+body+'\nend program\n'
 with tempfile.TemporaryDirectory() as td:
  p=pathlib.Path(td)/'p.f90';p.write_text(src);q=subprocess.run([str(C),str(p)],capture_output=True,text=True,timeout=15)
 try:check(q);results.append(dict(name=name,passed=True))
 except Exception as e:results.append(dict(name=name,passed=False,stdout=q.stdout,stderr=q.stderr,returncode=q.returncode,error=str(e)))
def need(c):
 if not c:raise AssertionError('condition failed')
for text in ['1','1 bad 3']:
 for index in [2,3,4]:
  run('failed section undefined '+text+str(index),'integer :: a(5),ios','a=-9\ntext="'+text+'"\nread(text,*,iostat=ios) a(2:4)\nprint *, a('+str(index)+')',lambda p:need(p.returncode!=0 and not p.stdout and ('undefined' in p.stderr.lower() or 'uninitialized' in p.stderr.lower())))
run('null preserves undefined selected','integer :: a(3),ios','text=",2,3"\nread(text,*,iostat=ios) a(:)\nprint *, a(1)',lambda p:need(p.returncode!=0 and ('undefined' in p.stderr.lower() or 'uninitialized' in p.stderr.lower())))
run('null later elements defined','integer :: a(3),ios','text=",2,3"\nread(text,*,iostat=ios) a(:)\nprint *, a(2),a(3)',lambda p:need(p.returncode==0 and p.stdout.split()==['2','3']))
for target in ['a(::0)','a(2:6)','a(0:2)','a(i:3)']:
 setup='a=-9\ntext="1 2 3"\n'
 run('runtime address rejection '+target,'integer :: a(5),ios,i',setup+'read(text,*,iostat=ios) '+target+'\nprint *, "AFTER"',lambda p:need(p.returncode!=0 and not p.stdout))
for target,control in [('a(:ios)','ios'),('a(:n),n','ios'),('a(1:2),a(4:5)','ios'),('a([1,2])','ios'),('(a(1:3))','ios')]:
 run('admission rejection '+target,'integer :: a(5),ios,n','a=-9\nn=2\nios=2\ntext="1 2 3"\nprint *, "NEVER"\nread(text,*,iostat='+control+') '+target,lambda p:need(p.returncode!=0 and not p.stdout))
run('no IOSTAT failure','integer :: a(5)','a=-9\ntext="1 bad 3"\nread(text,*) a(2:4)\nprint *, "AFTER"',lambda p:need(p.returncode!=0 and not p.stdout))
r=dict(status='passed' if all(x['passed'] for x in results) else 'failed',tests=len(results),candidate_sha256=hashlib.sha256(C.read_bytes()).hexdigest(),results=results)
(R/'057-read-sections-evidence/independent-read-sections-failures.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2));raise SystemExit(r['status']!='passed')
