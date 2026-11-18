from pathlib import Path
import hashlib, json, textwrap
ROOT=Path(__file__).resolve().parent
CASES=ROOT/'cases'
manifest=[]
def add(name,source,expected='',category='success',baseline=None,note='',**kw):
    p=CASES/(name+'.f90')
    if isinstance(source,bytes): p.write_bytes(source)
    else: p.write_text(textwrap.dedent(source).lstrip())
    manifest.append(dict(name=name,source='cases/'+p.name,category=category,baseline=baseline or ('run' if category=='success' else 'compile'),expected_stdout=expected,diagnostic='',note=note,**kw))
def mod(body,program):
    return 'module m\nimplicit none\ncontains\n'+textwrap.dedent(body).lstrip()+'end module\nprogram p\nuse m\nimplicit none\n'+textwrap.dedent(program).lstrip()+'end program\n'
original=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes()
start=original.index(b'recursive subroutine quick_sort(list, order)\r\n')
end=original.index(b'end subroutine quick_sort\r\n',start)+len(b'end subroutine quick_sort\r\n')
body=original[start:end]
wrapper=b'''module original_sort
implicit none
integer, parameter :: dp=kind(0d0)
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
post='''subroutine verify_sort(original)
real(kind=dp),intent(in)::original(:)
real(kind=dp)::x(size(original)),once(size(original))
integer::order(size(original)),again(size(original)),seen(size(original)),i,n
logical::sorted_ok,indexed_ok,permutation_ok,repeated_ok
n=size(original)
x=original
call quick_sort(x,order)
sorted_ok=.true.
indexed_ok=.true.
permutation_ok=.true.
seen=0
do i=1,n
  if(i>1) then
    if(x(i)<x(i-1)) sorted_ok=.false.
  end if
  if(order(i)<1.or.order(i)>n) then
    permutation_ok=.false.
    indexed_ok=.false.
  else
    seen(order(i))=seen(order(i))+1
    if(x(i)/=original(order(i))) indexed_ok=.false.
  end if
end do
if(any(seen/=1)) permutation_ok=.false.
once=x
call quick_sort(x,again)
repeated_ok=all(x==once)
seen=0
do i=1,n
  if(again(i)<1.or.again(i)>n) then
    repeated_ok=.false.
  else
    seen(again(i))=seen(again(i))+1
    if(x(i)/=once(again(i))) repeated_ok=.false.
  end if
end do
if(any(seen/=1)) repeated_ok=.false.
print *,n,sorted_ok,indexed_ok,permutation_ok,repeated_ok,sum(x),sum(order)
end subroutine
end module
program p
use original_sort
implicit none
real(kind=dp)::x(64)
integer::i,n
x=0.0_dp
call verify_sort(x(:0))
x(1)=-4.0_dp
call verify_sort(x(:1))
x(:2)=[2.0_dp,-2.0_dp]
call verify_sort(x(:2))
x(:6)=[6.0_dp,-2.0_dp,6.0_dp,3.0_dp,0.0_dp,-2.0_dp]
call verify_sort(x(:6))
x(:7)=[7.0_dp,-2.0_dp,7.0_dp,3.0_dp,0.0_dp,-2.0_dp,9.0_dp]
call verify_sort(x(:7))
x(:8)=5.0_dp
call verify_sort(x(:8))
do i=1,17
  x(i)=1.0_dp*(i-9)
end do
call verify_sort(x(:17))
do i=1,31
  x(i)=1.0_dp*(16-i)
end do
call verify_sort(x(:31))
do i=1,64
  x(i)=1.0_dp*(mod(17*i,13)-6)
end do
call verify_sort(x)
call verify_sort(x)
end program
'''
sums=[(0,0),(1,-4),(2,0),(6,11),(7,22),(8,40),(17,0),(31,0),(64,sum((17*i)%13-6 for i in range(1,65)))]
sums.append(sums[-1])
expected='\n'.join(f'{n} T T T T {s} {n*(n+1)//2}' for n,s in sums)
add('original_quick_sort',wrapper+body+post.encode(),expected,note='Entire original quick_sort including both internal routines is byte-identical with CRLF. Wrapper only defines real64 dp and elemental isnan generic. Tests sizes 0,1,2,6,7,8,17,31,64, duplicates, sorted/reverse, full permutation and value/index association, repeated calls.')
add('host_scalar_array',mod('''
subroutine host(a,n,answer)
integer,intent(inout)::a(:)
integer,intent(in)::n
integer,intent(out)::answer
integer::offset
logical::enabled
real(kind=kind(0d0))::scale
character(len=3)::tag
offset=3
enabled=.true.
scale=2.5d0
tag='abc'
call apply()
call finish()
contains
subroutine apply()
integer::i
if(enabled) then
 do i=1,n
  a(i)=a(i)+offset
 end do
end if
offset=offset+1
scale=scale+0.5d0
tag='xyz'
end subroutine
subroutine finish()
answer=sum(a)+offset
print *,enabled,scale,tag
end subroutine
end subroutine
''','''integer::a(3),answer
a=[1,2,3]
call host(a,3,answer)
print *,a,answer
'''),'T 3 xyz 4 5 6 19')
add('local_shadowing',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=7
call first()
call second()
answer=x
contains
subroutine first()
integer::x
x=100
call second()
print *,x
end subroutine
subroutine second()
x=x+1
end subroutine
end subroutine
''','''integer::answer
call host(answer)
print *,answer
'''),'100 9',note='second sees host x, never calling sibling first local x.')
add('dummy_shadowing',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::x,y
x=7
y=20
call child(y)
answer=x+y
contains
subroutine child(x)
integer,intent(inout)::x
x=x+2
end subroutine
end subroutine
''','''integer::answer
call host(answer)
print *,answer
'''),'29')
add('recursive_internal',mod('''
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::total
total=0
call descend(n)
answer=total
contains
recursive subroutine descend(k)
integer,intent(in)::k
integer::saved
saved=k
if(k>0) call descend(k-1)
total=total+saved
end subroutine
end subroutine
''','''integer::answer
call host(5,answer)
print *,answer
call host(3,answer)
print *,answer
'''),'15 6')
add('recursive_host_activation',mod('''
recursive subroutine host(depth,answer)
integer,intent(in)::depth
integer,intent(out)::answer
integer::x
x=10*depth
call child()
answer=x
contains
recursive subroutine child()
integer::below
below=0
if(depth>0) call host(depth-1,below)
x=x+below
call sibling()
end subroutine
subroutine sibling()
x=x+1
end subroutine
end subroutine
''','''integer::answer
call host(3,answer)
print *,answer
call host(1,answer)
print *,answer
'''),'64 12',note='An internal child calls a recursive host and then must return to its original host activation. Sibling calls use that activation.')
add('recursive_host_array_frames',mod('''
recursive subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::a(n)
a=n
call child()
answer=sum(a)
contains
recursive subroutine child()
integer::below
below=0
if(n>1) call host(n-1,below)
a(1)=a(1)+below
end subroutine
end subroutine
''','''integer::answer
call host(4,answer)
print *,answer
call host(2,answer)
print *,answer
'''),'30 5')
add('mutual_internal_recursion',mod('''
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::total
total=0
call first(n)
answer=total
contains
recursive subroutine first(k)
integer,intent(in)::k
total=total+1
if(k>0) call second(k-1)
end subroutine
recursive subroutine second(k)
integer,intent(in)::k
total=total+10
if(k>0) call first(k-1)
end subroutine
end subroutine
''','''integer::answer
call host(4,answer)
print *,answer
call host(3,answer)
print *,answer
'''),'23 22')
add('independent_internal_names',mod('''
subroutine first(answer)
integer,intent(out)::answer
integer::x
x=10
call child()
answer=x
contains
subroutine child()
x=x+1
end subroutine
end subroutine
subroutine second(answer)
integer,intent(out)::answer
integer::x
x=100
call child()
answer=x
contains
subroutine child()
x=x+2
end subroutine
end subroutine
''','''integer::x,y
call first(x)
call second(y)
print *,x,y
call first(x)
print *,x
'''),'11 102 11')
add('host_bounds_sections',mod('''
subroutine host(a,answer)
integer,intent(inout)::a(-2:)
integer,intent(out)::answer
integer::local(-1:1)
local=[1,2,3]
call child()
answer=sum(local)
contains
subroutine child()
a(-2)=a(-2)+10
a(-1:0)=a(-1:0)+local(0:1)
local(-1)=a(0)
end subroutine
end subroutine
''','''integer::a(5),answer
a=[1,2,3,4,5]
call host(a(2:4),answer)
print *,a,answer
'''),'1 12 5 7 5 12')
add('readonly_internal_function',mod('''
subroutine host(base,answer)
integer,intent(in)::base
integer,intent(out)::answer
answer=twice(3)+twice(4)
contains
integer function twice(x) result(y)
integer,intent(in)::x
y=base+x+x
end function
end subroutine
''','''integer::answer
call host(10,answer)
print *,answer
'''),'34')
add('recursive_internal_function',mod('''
subroutine host(base,n,answer)
integer,intent(in)::base,n
integer,intent(out)::answer
answer=total(n)
contains
recursive integer function total(k) result(y)
integer,intent(in)::k
if(k==0) then
y=base
else
y=k+total(k-1)
end if
end function
end subroutine
''','''integer::answer
call host(10,5,answer)
print *,answer
'''),'25')
add('host_parameters',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer,parameter::k=kind(0d0),n=3
real(kind=k)::x(n)
x=[1.0_k,2.0_k,3.0_k]
call child()
answer=int(sum(x))
contains
subroutine child()
real(kind=k)::b(n)
b=2.0_k
x=x+b
end subroutine
end subroutine
''','''integer::answer
call host(answer)
print *,answer
'''),'12')
add('expression_snapshot',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=7
call child((x))
answer=x
contains
subroutine child(y)
integer,intent(in)::y
x=100+y
end subroutine
end subroutine
''','''integer::answer
call host(answer)
print *,answer
'''),'107',note='Parenthesized actual is a value snapshot; child may write host x without dummy storage alias.')
add('host_actual_not_captured',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=7
call child(x)
answer=x
contains
subroutine child(y)
integer,intent(inout)::y
y=y+5
end subroutine
end subroutine
''','''integer::answer
call host(answer)
print *,answer
'''),'12',note='Passing a host local to a child is safe if the child does not otherwise access its host storage.')
add('early_return_host_write',mod('''
subroutine host(answer)
integer,intent(out)::answer
answer=0
call child()
answer=answer+1
contains
subroutine child()
answer=41
return
answer=99
end subroutine
end subroutine
''','''integer::answer
call host(answer)
print *,answer
'''),'42')
add('host_saved_state',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer,save::x=10
call child()
answer=x
contains
subroutine child()
x=x+1
end subroutine
end subroutine
''','''integer::a,b
call host(a)
call host(b)
print *,a,b
'''),'11 12',note='Existing SAVE semantics must not turn captured saved storage into per-activation copies.')
add('child_saved_state',mod('''
subroutine host(answer)
integer,intent(out)::answer
answer=0
call child()
contains
subroutine child()
integer,save::x=10
x=x+1
answer=x
end subroutine
end subroutine
''','''integer::a,b
call host(a)
call host(b)
print *,a,b
'''),'11 12')
add('pure_readonly_capture',mod('''
pure integer function host(x) result(y)
integer,intent(in)::x
y=child(3)
contains
pure integer function child(z) result(v)
integer,intent(in)::z
v=x+z
end function
end function
''','''print *,host(7)
'''),'10')
add('host_array_specification',mod('''
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
call child()
contains
subroutine child()
integer::a(n)
a=n
answer=sum(a)
end subroutine
end subroutine
''','''integer::answer
call host(4,answer)
print *,answer
'''),'16')
add('internal_depth_limit',mod('''
subroutine host()
call child()
contains
recursive subroutine child()
call child()
end subroutine
end subroutine
''','call host()\n'),category='runtime',baseline='compile',note='Deliberately infinite recursion: compile-only GNU and bounded interpreter failure, never execute GNU.')
# Compile-only cases are deliberately never invoked under GNU, including undefined aliases.
for name,inner in [('alias_direct','''subroutine child(y)
integer,intent(inout)::y
y=y+1
x=x+1
end subroutine
'''),('alias_transitive','''subroutine child(y)
integer,intent(inout)::y
y=y+1
call sibling()
end subroutine
subroutine sibling()
x=x+1
end subroutine
'''),('alias_readonly_conservative','''subroutine child(y)
integer,intent(in)::y
print *,x+y
end subroutine
''')]:
    add(name,mod('''subroutine host()
integer::x
x=7
call child(x)
contains
'''+inner+'end subroutine\n','call host()\n'),category='reject',note='GNU compile only. Direct/transitive host access aliases a dummy actual; conservative interpreter boundary, including harmless read-only alias.')
add('alias_array_element',mod('''
subroutine host()
integer::a(3)
a=1
call child(a(2))
contains
subroutine child(x)
integer,intent(inout)::x
x=x+1
a(1)=a(1)+1
end subroutine
end subroutine
''','call host()\n'),category='reject',note='Conservative whole-storage overlap for array element actual and host array reference; compile-only.')
add('capture_optional',mod('''
subroutine host(x)
integer,intent(in),optional::x
call child()
contains
subroutine child()
if(present(x)) print *,x
end subroutine
end subroutine
''','call host(1)\n'),category='reject')
add('capture_pointer',mod('''
subroutine host()
integer,target::x(2)
integer,pointer::q(:)
x=1
q=>x
call child()
contains
subroutine child()
print *,associated(q)
end subroutine
end subroutine
''','call host()\n'),category='reject')
add('capture_target',mod('''
subroutine host()
integer,target::x
x=1
call child()
contains
subroutine child()
x=x+1
end subroutine
end subroutine
''','call host()\n'),category='reject')
add('capture_allocatable',mod('''
subroutine host()
integer,allocatable::a(:)
allocate(a(2))
a=1
call child()
contains
subroutine child()
a=a+1
end subroutine
end subroutine
''','call host()\n'),category='reject')
add('capture_derived','''
module m
implicit none
type :: box
integer::x
end type
contains
subroutine host()
type(box)::a
a%x=1
call child()
contains
subroutine child()
a%x=a%x+1
end subroutine
end subroutine
end module
program p
use m
call host()
end program
''',category='reject')
add('pure_host_write',mod('''
pure subroutine host(answer)
integer,intent(out)::answer
answer=0
call child()
contains
pure subroutine child()
answer=1
end subroutine
end subroutine
''','''integer::answer
call host(answer)
'''),category='reject',baseline='reject')
add('intent_in_host_write',mod('''
subroutine host(x)
integer,intent(in)::x
call child()
contains
subroutine child()
x=1
end subroutine
end subroutine
''','call host(0)\n'),category='reject',baseline='reject')
add('ordinary_function_host_write',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=0
answer=child()
contains
integer function child() result(y)
x=x+1
y=x
end function
end subroutine
''','''integer::answer
call host(answer)
'''),category='reject',note='Standard-valid GNU; interpreter ordinary-function external-side-effect boundary.')
add('ordinary_function_transitive_host_write',mod('''
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=0
answer=child()
contains
integer function child() result(y)
call sibling()
y=x
end function
subroutine sibling()
x=x+1
end subroutine
end subroutine
''','''integer::answer
call host(answer)
'''),category='reject',note='Transitive side effect through sibling must be rejected before evaluation.')
add('nested_contains',mod('''
subroutine host()
call child()
contains
subroutine child()
call grandchild()
contains
subroutine grandchild()
end subroutine
end subroutine
end subroutine
''','call host()\n'),category='reject',baseline='reject',note='Fortran internal subprogram may not itself contain an internal subprogram.')
add('internal_not_module_visible','''
module m
implicit none
contains
subroutine host()
contains
subroutine child()
end subroutine
end subroutine
end module
program p
use m,only:child
call child()
end program
''',category='reject',baseline='reject')
add('internal_wrong_host',mod('''
subroutine first()
contains
subroutine child()
end subroutine
end subroutine
subroutine second()
call child()
end subroutine
''','call second()\n'),category='reject',baseline='reject',note='GNU rejects at link (unresolved external); internal child is not visible in sibling host.')
add('main_internal','''
program p
implicit none
integer::x
x=1
call child()
contains
subroutine child()
x=x+1
end subroutine
end program
''',category='reject',note='Initial bounded subset only supports internal procedures within module procedures.')
add('external_internal','''
subroutine host()
implicit none
integer::x
x=1
call child()
contains
subroutine child()
x=x+1
end subroutine
end subroutine
program p
call host()
end program
''',category='reject',note='Initial bounded subset only supports module hosts.')
add('internal_procedure_argument','''
module m
implicit none
contains
subroutine host()
integer::x
x=1
call invoke(child)
contains
subroutine child()
x=x+1
end subroutine
end subroutine
subroutine invoke(f)
interface
subroutine f()
end subroutine
end interface
call f()
end subroutine
end module
program p
use m
call host()
end program
''',category='reject',note='No escaping internal procedures, procedure dummy arguments or closure support in this feature.')
add('host_active_do_write',mod("""
subroutine host()
integer::i
do i=1,3
call child()
end do
contains
subroutine child()
i=9
end subroutine
end subroutine
""",'call host()\n'),category='runtime',baseline='compile',note='Invalid modification of an active host DO variable; never execute GNU. Runtime must protect aliased host binding.')
add('host_active_do_writable_actual',mod("""
subroutine host()
integer::i
do i=1,3
call child()
end do
contains
subroutine child()
call set_value(i)
end subroutine
end subroutine
subroutine set_value(x)
integer,intent(out)::x
x=9
end subroutine
""",'call host()\n'),category='runtime',baseline='compile',note='Indirect active-DO write through writable dummy; compile-only GNU.')
add('host_active_do_nested_loop',mod("""
subroutine host()
integer::i
do i=1,3
call child()
end do
contains
subroutine child()
do i=1,2
end do
end subroutine
end subroutine
""",'call host()\n'),category='runtime',baseline='compile',note='Nested internal loop reuses an active host DO variable; never execute GNU.')
add('capture_optional_specification',mod("""
subroutine host(n)
integer,intent(in),optional::n
call child()
contains
subroutine child()
integer::a(n)
a=1
print *,sum(a)
end subroutine
end subroutine
""",'call host(2)\n'),category='reject',note='Unsupported optional capture occurs only in a child specification expression, not its body.')
add('internal_shadows_module_procedure',mod("""
subroutine increment(x)
integer,intent(inout)::x
x=x+1000
end subroutine
subroutine host(answer)
integer,intent(out)::answer
integer::x
x=1
call increment()
answer=x
contains
subroutine increment()
x=x+2
end subroutine
end subroutine
""","""integer::answer
call host(answer)
print *,answer
"""),'3',note='The internal procedure hides the same-named module procedure only within its host.')
add('intent_in_host_writable_actual',mod("""
subroutine host(x)
integer,intent(in)::x
call child()
contains
subroutine child()
call set_value(x)
end subroutine
end subroutine
subroutine set_value(x)
integer,intent(out)::x
x=3
end subroutine
""",'call host(2)\n'),category='reject',baseline='reject')
add('host_character_substring',mod("""
subroutine host(answer)
character(len=5),intent(out)::answer
character(len=5)::text
text='abcde'
call child()
answer=text
contains
subroutine child()
text(2:4)='XYZ'
end subroutine
end subroutine
""","""character(len=5)::answer
call host(answer)
print *,answer
"""),'aXYZe')
add('host_empty_array',mod("""
subroutine host(n,answer)
integer,intent(in)::n
integer,intent(out)::answer
integer::a(n)
a=0
call child()
answer=sum(a)
contains
subroutine child()
a=a+1
end subroutine
end subroutine
""","""integer::answer
call host(0,answer)
print *,answer
call host(3,answer)
print *,answer
"""),'0 3')
add('capture_host_function_result',mod("""
integer function host() result(y)
y=3
y=child()
contains
integer function child() result(z)
z=y+2
end function
end function
""",'print *,host()\n'),category='reject',note='Standard-valid result-variable host association is excluded from the bounded interpreter subset.')
add('elemental_host_contains',mod("""
elemental integer function host(x) result(y)
integer,intent(in)::x
y=child()
contains
pure integer function child() result(z)
z=x+1
end function
end function
""",'print *,host(2)\n'),category='reject',baseline='compile',note='GNU accepts this standard-valid ELEMENTAL host with a pure internal function; the bounded interpreter subset excludes ELEMENTAL hosts.')
add('impure_elemental_child_host_counter',mod("""
subroutine host(values,last)
integer,intent(out)::values(3),last
integer::counter
counter=0
values=next_value([10,10,10])
last=counter
contains
impure elemental integer function next_value(x) result(y)
integer,intent(in)::x
counter=counter+1
y=x+counter
end function
end subroutine
""","""integer::values(3),last
call host(values,last)
print *,values,last
"""),'11 12 13 3',note='Existing IMPURE ELEMENTAL effect policy applies to internal child functions. Captured host counter changes once per array element.')
add('simple_mutable_capture',mod("""
subroutine host(answer)
integer,intent(out)::answer
integer::offset
offset=7
answer=child(3)
contains
simple integer function child(x) result(y)
integer,intent(in)::x
y=x+offset
end function
end subroutine
""","""integer::answer
call host(answer)
print *,answer
"""),category='reject',baseline='skip',note='SIMPLE forbids reading mutable host storage, including an otherwise read-only capture. GNU is explicitly skipped; no native SIMPLE conformance or PURE-lowered semantics are claimed.',gnu_skip_reason="SIMPLE is not evaluated under this suite's GNU Fortran 2018 mode")
add('simple_parameter_capture',mod("""
subroutine host(answer)
integer,intent(out)::answer
integer,parameter::offset=7
answer=child(3)
contains
simple integer function child(x) result(y)
integer,intent(in)::x
y=x+offset
end function
end subroutine
""","""integer::answer
call host(answer)
print *,answer
"""),'10',baseline='skip',note='SIMPLE may reference a host named constant. GNU is explicitly skipped; no native SIMPLE conformance or PURE lowering is claimed.',gnu_skip_reason="SIMPLE is not evaluated under this suite's GNU Fortran 2018 mode")
add('host_bound_composition',mod("""
subroutine host(n,values)
integer,intent(in)::n
integer,intent(inout)::values(:)
call child(values)
contains
subroutine child(a)
integer,intent(inout)::a(n)
character(len=n)::label
label=repeat('x',n)
a=a+len(label)
print *,len(label),label
end subroutine
end subroutine
""","""integer::a3(3),a1(1),a0(0)
a3=[1,2,3]
a1=[9]
call host(3,a3)
print *,a3
call host(1,a1)
print *,a1
call host(0,a0)
"""),'3 xxx 4 5 6 1 x 10 0',note='The same captured host INTEGER INTENT(IN) dummy n supplies an internal explicit-shape dummy bound and local CHARACTER length. Exercises lengths three, one, and zero. No host-local or host-array-inquiry bound claim.')
for case in manifest:
    if case['name'].startswith('capture_'):
        case['diagnostic']='host capture'
    if case['name'].startswith('alias_'):
        case['diagnostic']='also referenced through callee host/USE association'
    if case['name']=='simple_mutable_capture': case['diagnostic']='host capture'
    if case['name']=='internal_depth_limit': case['diagnostic']='call depth limit'
    if case['name'].startswith('host_active_do'):
        case['diagnostic']='active DO variable'
        case['baseline']='reject'
    if case['name']=='capture_optional_specification': case['baseline']='reject'
manifest_doc=dict(description='Bounded internal procedures, exact original quick_sort, activation semantics, and safety boundaries.',original=dict(path='../utilities_slices/source/xutilities.f90',sha256=hashlib.sha256(original).hexdigest(),body_sha256=hashlib.sha256(body).hexdigest(),start_line=original[:start].count(b'\n')+1,end_line=original[:end].count(b'\n'),body_bytes=len(body),crlf_lines=body.count(b'\r\n')),cases=manifest)
(ROOT/'manifest.json').write_text(json.dumps(manifest_doc,indent=2)+'\n')
print(len(manifest),'cases; original',manifest_doc['original'])
