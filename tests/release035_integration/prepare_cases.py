#!/usr/bin/env python3
"""Generate only new synthetic composition fixtures and exact original wrapper."""
from pathlib import Path
import hashlib,json,textwrap
ROOT=Path(__file__).resolve().parent
CASES=ROOT/'cases';CASES.mkdir(exist_ok=True)
(ROOT/'original').mkdir(exist_ok=True)
cases=[]
def add(name,source,expected='',category='success',baseline=None,**kw):
    data=textwrap.dedent(source).lstrip().encode() if isinstance(source,str) else source
    (CASES/(name+'.f90')).write_bytes(data)
    cases.append(dict(name=name,source='cases/'+name+'.f90',category=category,
        baseline=baseline or ('run' if category=='success' else 'compile'),
        expected_stdout=expected,compare_mode='exact',**kw))
def mod(body,main):
    return 'module composition\nimplicit none\ncontains\n'+textwrap.dedent(body).lstrip()+\
           'end module\nprogram main\nuse composition\nimplicit none\n'+textwrap.dedent(main).lstrip()+'end program\n'
add('live_saved_grouped',"""module live_composition
implicit none
contains
subroutine host(n,a)
integer,intent(in)::n
integer,intent(inout)::a(:)
integer,save::calls=0
integer::state
character(5)::char
state=n
char='a b  '
calls=calls+1
call descend(n)
write(*,'("frame",2(1x,i0)," [",a,"]")')calls,state,char
write(*,'("array",2(1x,i0))')a
contains
recursive subroutine descend(k)
integer,intent(in)::k
integer::local
local=k
if(k>0)call descend(k-1)
state=state+local
a=a+local
call sibling()
end subroutine
subroutine sibling()
char='x y  '
state=state+1
end subroutine
end subroutine
end module
program main
use live_composition
implicit none
integer::a(2)
a=[1,2]
call host(2,a)
call host(1,a)
end program
""",
    'frame 1 8 [x y  ]\narray 4 5\nframe 2 4 [x y  ]\narray 5 6\n')
original=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes()
original_hash='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
assert hashlib.sha256(original).hexdigest()==original_hash
start=original.index(b'recursive subroutine quick_sort(list, order)\r\n')
end=original.index(b'end subroutine quick_sort\r\n',start)+len(b'end subroutine quick_sort\r\n')
body=original[start:end]
assert len(body)==2517 and body.count(b'\r\n')==73
assert hashlib.sha256(body).hexdigest()=='c12792b8b58af0814e11fabc91840133b8f943f306e32ece55cb68cab6529366'
prefix=b'''module original_sort
implicit none
integer,parameter::dp=kind(0d0)
interface isnan
module procedure isnan_real
end interface
contains
elemental function isnan_real(x) result(tf)
real(kind=dp),intent(in)::x
logical::tf
tf=x/=x
end function
'''
wrapper=prefix+body+b'end module\n'
(ROOT/'original/quick_sort_module.f90').write_bytes(wrapper)
provenance=dict(original_source='../utilities_slices/source/xutilities.f90',original_source_sha256=original_hash,
 wrappers=[dict(path='original/quick_sort_module.f90',sha256=hashlib.sha256(wrapper).hexdigest(),routines=[dict(
 name='quick_sort',source_byte_start=start,source_byte_end_exclusive=end,wrapper_byte_start=len(prefix),
 sha256=hashlib.sha256(body).hexdigest(),bytes=2517,crlf_lines=73,source_start_line=8870,source_end_line=8942)])])
(ROOT/'original-source-map.json').write_text(json.dumps(provenance,indent=2)+'\n')
add('original_sort_grouped', '''program main
use original_sort
implicit none
real(dp)::a(8),before(8),empty(0)
integer::order(8),seen(8),zero(0),i
before=[4.0_dp,-2.0_dp,4.0_dp,0.0_dp,7.0_dp,-2.0_dp,1.0_dp,4.0_dp]
a=before
call quick_sort(a,order)
if(any(a/=[-2.0_dp,-2.0_dp,0.0_dp,1.0_dp,4.0_dp,4.0_dp,4.0_dp,7.0_dp]))error stop 1
seen=0
do i=1,8
if(order(i)<1.or.order(i)>8)error stop 2
seen(order(i))=seen(order(i))+1
if(a(i)/=before(order(i)))error stop 3
end do
if(any(seen/=1))error stop 4
write(*,'("sorted:",8(1x,i0))')int(a)
write(*,'("checked:",2(1x,i0))')size(a),sum(order)
call quick_sort(empty,zero)
write(*,'("empty:",1x,i0)')size(zero)
before=a
call quick_sort(a,order)
if(any(a/=before))error stop 5
seen=0
do i=1,8
if(order(i)<1.or.order(i)>8)error stop 6
seen(order(i))=seen(order(i))+1
if(a(i)/=before(order(i)))error stop 7
end do
if(any(seen/=1))error stop 8
write(*,'("repeat:",8(1x,i0))')int(a)
end program
''','sorted: -2 -2 0 1 4 4 4 7\nchecked: 8 36\nempty: 0\nrepeat: -2 -2 0 1 4 4 4 7\n',support_sources=['original/quick_sort_module.f90'])
add('recursive_identity_frozen',mod('''
recursive subroutine host(depth,answer)
integer,intent(in)::depth
integer,intent(out)::answer
integer::work(depth+1),marker
work=depth
marker=10*depth
call child()
contains
recursive subroutine child()
integer::below
below=0
if(depth>0)call host(depth-1,below)
call sibling()
answer=below+marker+sum(work)
end subroutine
subroutine sibling()
work=work+1
marker=marker+sum(work)
end subroutine
end subroutine
''','''integer::answer
call host(3,answer)
write(*,'("depth3:",1x,i0)')answer
call host(1,answer)
write(*,'("depth1:",1x,i0)')answer
call host(0,answer)
write(*,'("depth0:",1x,i0)')answer
'''),'depth3: 120\ndepth1: 20\ndepth0: 2\n')
add('descriptor_inquiry_frozen_capture',mod('''
subroutine host(values)
integer,allocatable,intent(inout)::values(:)
integer::work(size(values)),entry
integer,save::calls=0
entry=size(values)
calls=calls+1
work=calls
call child()
deallocate(values)
allocate(values(1))
values=99
call child()
write(*,'("frozen:",4(1x,i0))')calls,entry,size(work),sum(work)
contains
subroutine child()
work=work+1
end subroutine
end subroutine
''','''integer,allocatable::a(:)
allocate(a(-2:0))
call host(a)
call host(a)
deallocate(a)
allocate(a(0))
call host(a)
'''),'frozen: 1 3 3 9\nfrozen: 2 1 1 4\nfrozen: 3 0 0 0\n',scope_note='ALLOCATABLE host values are not captured. Its SIZE freezes the ordinary host work array, which the child mutates before and after descriptor reallocation.')
add('child_saved_independent_hosts',mod('''
subroutine first(answer)
integer,intent(out)::answer
integer::state
state=100
call char()
contains
subroutine char()
integer,save::visits=0
visits=visits+1
state=state+visits
answer=state
end subroutine
end subroutine
subroutine second(answer)
integer,intent(out)::answer
integer::state
state=200
call char()
contains
subroutine char()
integer,save::visits=10
visits=visits+1
state=state+visits
answer=state
end subroutine
end subroutine
''','''integer::a,b,c,d
call first(a)
call second(b)
call first(c)
call second(d)
write(*,'("saved:",4(1x,i0))')a,b,c,d
'''),'saved: 101 211 102 212\n')
add('quoted_char_substring',mod('''
subroutine host()
character(15)::char
character(30)::record
char='char(n) says hi'
call patch()
call show()
contains
subroutine patch()
char(9:12)='asks'
end subroutine
subroutine show()
write(record,'(2(a))')'"',char
write(*,'("char(n) [",a,"] [",a,"]")')char,trim(record)
end subroutine
end subroutine
''','''call host()
'''),'char(n) [char(n) asks hi] ["char(n) asks hi]\n')
add('pure_read_impure_elemental',mod('''
subroutine host(a,total)
integer,intent(out)::a(3),total
integer::counter,offset
counter=0
offset=10
a=next([1,2,3])
total=peek()
contains
impure elemental integer function next(x) result(y)
integer,intent(in)::x
counter=counter+1
y=x+offset+counter
end function
pure integer function peek() result(y)
y=counter+offset
end function
end subroutine
''','''integer::a(3),total
call host(a,total)
write(*,'("effects:",4(1x,i0))')a,total
call host(a,total)
write(*,'("reset:",4(1x,i0))')a,total
'''),'effects: 12 14 16 13\nreset: 12 14 16 13\n')
add('host_section_lower_bounds',mod('''
subroutine host(a)
integer,intent(inout)::a(-2:)
integer::local(-1:1)
local=[10,20,30]
call child()
call finish()
contains
subroutine child()
a(-2:0)=a(-2:0)+local
local=local+1
end subroutine
subroutine finish()
a(0)=a(0)+sum(local)
end subroutine
end subroutine
''','''integer::a(5)
a=[1,2,3,4,5]
call host(a(2:4))
write(*,'("section:",5(1x,i0))')a
'''),'section: 1 12 23 97 5\n')
add('frozen_child_host_bound',mod('''
subroutine host(n)
integer,intent(inout)::n
call child()
contains
subroutine child()
integer::work(n),entry
character(n)::char
entry=n
work=7
char=' x '
n=1
write(*,'("entry:",3(1x,i0)," [",a,"]")')entry,size(work),len(char),char
end subroutine
end subroutine
''','''integer::n
n=3
call host(n)
write(*,'("host:",1x,i0)')n
n=0
call host(n)
'''),'entry: 3 3 3 [ x ]\nhost: 1\nentry: 0 0 0 []\n')
add('grouped_atomic_failure',mod('''
subroutine host(values)
integer,intent(in)::values(:)
write(*,'(a)')'before grouped child'
call child()
contains
subroutine child()
write(*,'(a,2(i0),a)')'must not leak',values,'done'
end subroutine
end subroutine
''','''call host([12,34,56])
'''),category='runtime',diagnostic='PRINT format descriptor and item type differ',completed_stdout='before grouped child\n',scope_note='GNU compiles only; intentionally invalid transfer is not executed.')
add('list_atomic_cap_failure',mod('''
subroutine host()
character(65536)::a(256)
a=repeat('x',65536)
write(*,'(a)')'before list child'
call child()
contains
subroutine child()
write(*,*)a
end subroutine
end subroutine
''','''call host()
'''),category='runtime',diagnostic='list-directed output exceeds 16777216 characters',completed_stdout='before list child\n',scope_note='Unchanged 16MiB list staging cap. GNU compiles only; child failure must preserve only the prior complete record.')
add('formatted_atomic_cap_failure',mod('''
subroutine host()
character(32769)::a
a=repeat('x',32769)
write(*,'(a)')'before formatted child'
call child()
contains
subroutine child()
write(*,'(2(a))')a,a
end subroutine
end subroutine
''','''call host()
'''),category='runtime',diagnostic='formatted PRINT record exceeds 65536 characters',completed_stdout='before formatted child\n',scope_note='Unchanged 65536-character formatted-record cap, below list cap. GNU compiles only.')
add('list_larger_than_formatted_cap',mod('''
subroutine host()
character(32769)::a
a=repeat('x',32769)
call child()
contains
subroutine child()
write(*,*)a,a
end subroutine
end subroutine
''','''call host()
'''),' '+'x'*65538+'\n',scope_note='A 65538-character live-host list record succeeds under the separate 16MiB list cap. The exact oracle includes the leading list-directed blank.')
for name,decl,init,read in [
 ('allocatable_capture_boundary','integer,allocatable::a(:)','allocate(a(2))\na=3','sum(a)'),
 ('runtime_character_capture_boundary','character(n)::a',"a='xx'",'len(a)'),
]:
 add(name,mod('''
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
'''+decl+'\n'+init+'''
call child()
contains
subroutine child()
answer='''+read+'''
end subroutine
end subroutine
''','''integer::answer
call host(2,answer)
write(*,'(i0)')answer
'''),category='reject',diagnostic='host capture',scope_note='Standard-valid GNU compile-only; excluded captured host storage kind, not a claim of full closure support.')
add('pure_transitive_host_write',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::state
state=1
answer=peek()
contains
pure integer function peek() result(x)
call mutate()
x=state
end function
subroutine mutate()
state=state+1
end subroutine
end subroutine
''','''integer::answer
call host(answer)
'''),category='reject',baseline='reject',diagnostic='PURE procedure cannot invoke an impure procedure')
add('ordinary_transitive_host_write',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::state
state=1
answer=peek()
contains
integer function peek() result(x)
call mutate()
x=state
end function
subroutine mutate()
state=state+1
end subroutine
end subroutine
''','''integer::answer
call host(answer)
'''),category='reject',diagnostic='External side effects inside ordinary functions are unsupported',scope_note='GNU-valid ordinary function effects exceed the bounded interpreter policy. GNU compile-only.')
add('readonly_alias_boundary',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::state
state=3
call child(state)
contains
subroutine child(x)
integer,intent(in)::x
answer=state+x
end subroutine
end subroutine
''','''integer::answer
call host(answer)
'''),category='reject',diagnostic='also referenced through callee host/USE association',scope_note='Conservative whole-storage alias boundary even for a read-only input. GNU compile-only.')
add('parenthesized_snapshot_allowed',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::state
state=3
call child((state))
contains
subroutine child(x)
integer,intent(in)::x
state=state+10
answer=state+x
end subroutine
end subroutine
''','''integer::answer
call host(answer)
write(*,'("snapshot:",1x,i0)')answer
'''),'snapshot: 16\n')
(ROOT/'manifest.json').write_text(json.dumps(dict(description='Independent bounded internal-procedure composition; GNU stage distinctions and byte preservation are explicit.',cases=cases),indent=2)+'\n')
