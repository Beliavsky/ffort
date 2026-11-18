#!/usr/bin/env python3
"""Bounded observational memory profile, not deterministic fault injection."""
import argparse,hashlib,json,pathlib,resource,subprocess,tempfile,time
R=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--result',default='character-memory-profile.json');a=p.parse_args()
exe=pathlib.Path(a.candidate).resolve();before=hashlib.sha256(exe.read_bytes()).hexdigest();rows=[]
for width in [0,1]:
 source=f'''program p
implicit none
character({width}),allocatable::x(:)
integer::n
n={width}
allocate(x(16384))
x='q'
call outer(n,x)
if(len(x)/={width}.or.size(x)/=8192) error stop 1
print '(a)','ok'
contains
subroutine outer(n,a)
integer,intent(inout)::n
character(len=n),allocatable,intent(inout)::a(:)
call inner(n,a)
end subroutine
subroutine inner(n,a)
integer,intent(inout)::n
character(len=n),allocatable,intent(inout)::a(:)
print '(a)','inner entered'
n=2
a=a(1:8192)
end subroutine
end program
'''
 for mib in [64,512]:
  with tempfile.TemporaryDirectory(prefix='release042-memory-') as tmp:
   f=pathlib.Path(tmp)/'probe.f90';f.write_text(source)
   def limit():resource.setrlimit(resource.RLIMIT_AS,(mib*1024**2,mib*1024**2))
   start=time.monotonic()
   try:
    r=subprocess.run([str(exe),'--max-steps','5000000',str(f)],capture_output=True,text=True,timeout=90,preexec_fn=limit)
    row=dict(status=r.returncode,stdout=r.stdout,stderr=r.stderr,body_entered='inner entered\n' in r.stdout)
   except subprocess.TimeoutExpired as e:row=dict(status=None,stdout=str(e.stdout),stderr=str(e.stderr),timeout=True)
   row.update(width=width,elements=16384,address_limit_mib=mib,seconds=time.monotonic()-start,source=source,source_sha256=hashlib.sha256(source.encode()).hexdigest())
   row['classification']='clean success' if row['status']==0 and row['stdout']=='inner entered\nok\n' and not row['stderr'] else 'observed constrained failure; stage not injected'
   rows.append(row)
assert hashlib.sha256(exe.read_bytes()).hexdigest()==before
result=dict(candidate_sha256=before,scope='Unix RLIMIT_AS characterization only. Does not isolate outer/argument/payload allocation stages, certify OOM recovery, or replace fault injection. No limits above 512 MiB.',records=rows)
(R/a.result).write_text(json.dumps(result,indent=2)+'\n')
for row in rows:print(row['width'],row['address_limit_mib'],row['status'],row['classification'])
