import subprocess,pathlib,tempfile,json,hashlib
R=pathlib.Path(__file__).resolve().parents[1];C=R/'057-read-sections-work/build/gfortran_A86CEF2075723C1E/app/fortfront-interpreter';G=R.parent/'scifort-verification/toolchain/bin/gfortran';results=[]
for typ,init in [('integer','-9'),('character(100)',"'old'")]:
 for intent in ['inout','out']:
  src=f'''program p
implicit none
{typ} :: a(5)
integer :: ios
a={init}
call fill(a,3,ios)
print *,ios==0
print *,a
contains
subroutine fill(x,n,ios)
{typ},intent({intent}) :: x(:)
integer,intent(in) :: n
integer,intent(out) :: ios
character(80) :: text
x={init}
text="1 2 3"
read(text,*,iostat=ios) x(:n)
end subroutine
end program
'''
  with tempfile.TemporaryDirectory() as td:
   p=pathlib.Path(td)/'p.f90';e=pathlib.Path(td)/'p';p.write_text(src)
   cc=subprocess.run([str(G),'-fcheck=all',str(p),'-o',str(e)],capture_output=True,text=True)
   if cc.returncode: results.append(dict(name=typ+intent,passed=False,stderr=cc.stderr));continue
   g=subprocess.run([str(e)],capture_output=True,text=True);q=subprocess.run([str(C),str(p)],capture_output=True,text=True)
   results.append(dict(name=typ+intent,passed=g.returncode==0 and q.returncode==0 and g.stdout.split()==q.stdout.split(),expected=g.stdout,actual=q.stdout,stderr=q.stderr))
r=dict(status='passed' if all(x['passed'] for x in results) else 'failed',tests=len(results),candidate_sha256=hashlib.sha256(C.read_bytes()).hexdigest(),results=results)
(R/'057-read-sections-evidence/independent-read-sections-procedures.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2));raise SystemExit(r['status']!='passed')
