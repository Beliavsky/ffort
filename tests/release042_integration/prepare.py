from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent
cases=[]
def add(name,source,expected='ok\n',gnu='run',diagnostic='',numeric=None):
 if 'type :: pair' in source or 'type::pair' in source:
  import re
  m=re.search(r'type\s*::\s*pair\n.*?end type\n',source,re.S)
  definition=m.group();source=source[:m.start()]+source[m.end():]
  source='module record_types\nimplicit none\n'+definition+'end module\n'+source.replace('program p\n','program p\nuse record_types\n',1)
 p=R/'cases'/f'{name}.f90';p.write_text(source)
 c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category='runtime' if diagnostic else 'success',gnu=gnu,expected=expected,diagnostic=diagnostic,note='Interpreter resource/undefined-state policy; GNU compile only.' if gnu=='compile' else '')
 if name=='captured_host_length_reject':c['category']='reject'
 if numeric:c.pop('expected');c['numeric']=numeric
 cases.append(c)
def prog(decl,body,subs=''):
 return 'program p\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+subs if subs else '')+'end program\n'
for rank,shape,bounds in [(1,'-2:999997','a(:)'),(3,'-2:97,4:103,-7:92','a(:,:,:)')]:
 add(f'zero_length_cap_rank{rank}',prog(f'character(0),allocatable :: x'+('(:)' if rank==1 else '(:,:,:)'),"call fill(0,x)\nif (len(x)/=0.or.size(x)/=2) error stop 1\nprint '(a)','ok'",f'''subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: {bounds}
integer :: s
allocate(a({shape}),stat=s)
if(s/=0.or.size(a)/=1000000.or.len(a)/=0) error stop 2
if(lbound(a,1)/=-2) error stop 3
deallocate(a)
allocate(a({('1000001' if rank==1 else '100,100,101')}),stat=s)
if(s==0.or.allocated(a).or.len(a)/=0) error stop 4
allocate(a({('-1:0' if rank==1 else '-1:0,1:1,1:1')}),stat=s)
if(s/=0) error stop 5
end subroutine
'''),gnu='compile')
base='''type :: pair
 integer :: left,right
end type
type(pair) :: a,b
character(4),allocatable :: x(:)
character(2),allocatable :: y(:)
integer :: n'''
sub='''subroutine outer(r,n,v)
type(pair),intent(inout)::r
integer,intent(inout)::n
character(len=n),allocatable,intent(out)::v(:)
call inner(r,n,v)
end subroutine
subroutine inner(r,n,v)
type(pair),intent(inout)::r
integer,intent(inout)::n
character(len=n),allocatable,intent(out)::v(:)
n=1
r%left=r%left+1
allocate(v(-1:0))
v='Q'
end subroutine
'''
add('mixed_record_nested_frozen',prog(base,"""a=pair(7,9)
b=a
n=4
call outer(a,n,x)
if(n/=1.or.len(x)/=4.or.lbound(x,1)/=-1) error stop 1
if(a%left/=8.or.a%right/=9.or.b%left/=7.or.b%right/=9) error stop 2
n=2
call outer(a,n,y)
if(n/=1.or.len(y)/=2.or.a%left/=9.or.b%left/=7) error stop 3
print '(a)',x(-1)
print '(a)',y(0)""",sub),expected='Q   \nQ \n')
for count in [1,2]:
 add(f'caller_element_copyout_{count}',prog('integer,allocatable :: owned(:)\ncharacter(0),allocatable :: x(:)',f"allocate(owned(999999))\ncall fill(0,x)\nif(size(x)/={count}.or.lbound(x,1)/=-2) error stop 1\nprint '(a)','ok'",f'''subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
allocate(a(-2:{count-3}))
end subroutine
'''),expected='' if count==2 else 'ok\n',gnu='compile' if count==2 else 'run',diagnostic='limit' if count==2 else '')
add('character_byte_boundary',prog('character(65536),allocatable::x(:)',"call fill(65536,x)\nif(size(x)/=1.or.len(x)/=65536) error stop 1\nprint '(a)','ok'",'''subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
integer::s
allocate(a(-7:248),stat=s)
if(s/=0.or.size(a)/=256.or.len(a)/=65536) error stop 2
deallocate(a)
allocate(a(257),stat=s)
if(s==0.or.allocated(a).or.len(a)/=65536) error stop 3
allocate(a(1),stat=s)
if(s/=0) error stop 4
end subroutine
'''),gnu='compile')
add('caller_byte_copyout',prog('character(1024),allocatable::owned(:),x(:)',"allocate(owned(16383))\ncall fill(1024,x)\nprint '(a)','body leaked'",'''subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
allocate(a(2))
end subroutine
'''),expected='',gnu='compile',diagnostic='character')
add('forall_zero_cartesian',prog('integer,allocatable::a(:,:)\ninteger::i,j,rhs',"forall(i=1:0,j=1:1000000) a(i,j)=rhs\nforall(i=1:1000000,j=1:0) a(i,j)=rhs\nprint '(a)','ok'"))
add('captured_host_length_reject',"""module captured
implicit none
integer::n
contains
subroutine fill(a)
character(len=n),allocatable,intent(out)::a(:)
n=1
allocate(a(1))
a='Z'
end subroutine
end module
program p
use captured
implicit none
character(3),allocatable::x(:)
n=3
call fill(x)
if(n/=1.or.len(x)/=3) error stop 1
print '(a)',x(1)
end program
""",expected='',gnu='compile',diagnostic='CHARACTER LEN requires a constant or supported specification expression')
add('nested_inout_reallocation',prog('character(4),allocatable::x(:)\ninteger::n',"allocate(x(-1:2))\nx=['abcd','efgh','ijkl','mnop']\nn=4\ncall outer(n,x)\nif(n/=1.or.len(x)/=4.or.size(x)/=2) error stop 1\nprint '(a)',x(1)\nprint '(a)',x(2)",'''subroutine outer(n,a)
integer,intent(inout)::n
character(len=n),allocatable,intent(inout)::a(:)
call inner(n,a)
end subroutine
subroutine inner(n,a)
integer,intent(inout)::n
character(len=n),allocatable,intent(inout)::a(:)
n=1
a=a(0:1)
end subroutine
'''),expected='efgh\nijkl\n')
for state,init in [('unallocated',''),('empty','allocate(x(0))'),('allocated',"allocate(x(1))\nx='abc'")]:
 add('alias_'+state,prog('character(3),allocatable::x(:)',init+'\ncall fill(3,x,x)', '''subroutine fill(n,a,b)
integer,intent(in)::n
character(len=n),allocatable,intent(inout)::a(:),b(:)
print '(a)','body leaked'
end subroutine
'''),expected='',gnu='compile',diagnostic='overlapping allocatable descriptors')
add('undefined_record_copy',prog('type::pair\ninteger::left,right\nend type\ntype(pair)::a,b\ncharacter(2),allocatable::x(:)',"a=pair(7,9)\nb=a\ncall fill(2,a,x)\nif(b%left/=7.or.b%right/=9) error stop 1\nprint *,a%right",'''subroutine fill(n,r,v)
integer,intent(in)::n
type(pair),intent(out)::r
character(len=n),allocatable,intent(out)::v(:)
r%left=8
allocate(v(1))
v='ok'
end subroutine
'''),expected='',gnu='compile',diagnostic='uninitialized')
add('undefined_character_copyout',prog('character(2),allocatable::x(:)',"call fill(2,x)\nprint *,x(2)",'''subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
allocate(a(2))
a(1)='ok'
end subroutine
'''),expected='',gnu='compile',diagnostic='uninitialized')
add('record_signed_zero',prog('type::pair\nreal(8)::a,b\nend type\ntype(pair)::x,y',"x=pair(-0.0d0,2.0d0)\ny=x\nx%b=3.0d0\nprint *,y%a,y%b,x%b"),numeric=['-0','2','3'])
p=R/'synthetic-manifest.json';p.write_text(json.dumps({'scope':'Independently authored 0.42 composition; original fixtures untouched; default cap 1000000 only.','cases':cases},indent=2)+'\n')
r=R/'run_tests.py';s=r.read_text();import re
s=re.sub("MANIFEST_SHA256='[^']*'", "MANIFEST_SHA256='"+hashlib.sha256(p.read_bytes()).hexdigest()+"'",s)
s=s.replace('release041','release042').replace('[cand,src]','[cand,\'--max-steps\',\'50000000\',src]').replace('timeout=30','timeout=120')
r.write_text(s)
