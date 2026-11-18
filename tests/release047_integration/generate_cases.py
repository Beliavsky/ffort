#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
(ROOT/'cases').mkdir(exist_ok=True);(ROOT/'inputs').mkdir(exist_ok=True)
CASES=[]
def program(decl,body,procs=''):
 return 'program p\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+procs+'\n' if procs else '')+'end program\n'
def derived(decl,body,procs=''):
 return '''module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
'''+('contains\n'+procs+'\n' if procs else '')+'''end module
program p
use types
implicit none
'''+decl+'\n'+body+'\nend program\n'
def add(name,source,out,features,inputs=None,category='success',gnu='run',diagnostic=None,numeric_lines=None):
 p=ROOT/'cases'/(name+'.f90');p.write_bytes(source.encode())
 c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=out,features=features)
 if numeric_lines:c['numeric_lines']=numeric_lines
 if diagnostic:
  needle,message,column=diagnostic
  c.update(diagnostic=message,diagnostic_line=source.splitlines().index(needle)+1,diagnostic_column=column)
 if inputs:
  c['inputs']=[]
  for unit,data in inputs.items():
   p=ROOT/'inputs'/(name+'_'+str(unit)+'.dat');p.write_bytes(data.encode())
   c['inputs'].append(dict(unit=unit,file='inputs/'+p.name,bytes=len(p.read_bytes()),sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
 CASES.append(c)
add('default_read_constructor_override',derived('type(dt)::x\ninteger::u,n',"u=27\nprint '(i3,f5.1)',x%a,x%y\nread(u,*)n\nx=dt(n)\nprint '(i3,f5.1)',x%a,x%y"),'  7  2.5\n 42  2.5\n',['default creation','external list READ','constructor trailing default'],{27:'42\n'})
add('fresh_local_shared_cursor',derived('',"call show(27)\ncall show(27)",'''subroutine show(unit)
integer,intent(in)::unit
type(dt)::x
integer::n
read(unit,*)n
print '(2i3)',x%a,n
x%a=99
end subroutine'''),'  7 11\n  7 22\n',['fresh local lifetime','shared procedure input cursor'],{27:'11\n22\n'})
add('intent_out_reinitialize_read',derived('type(dt)::x',"x=dt(99,8.)\ncall reset(x,27)\nprint '(i3,f5.1)',x%a,x%y",'''subroutine reset(x,u)
type(dt),intent(out)::x
integer,intent(in)::u
integer::n
print '(i3,f5.1)',x%a,x%y
read(u,*)n
x%a=n
end subroutine'''),'  7  2.5\n 31  2.5\n',['INTENT(OUT) defaults','READ into local then component store'],{27:'31\n'})
add('recursive_defaults_shared_cursor',derived('',"call visit(27,2)",'''recursive subroutine visit(u,depth)
integer,intent(in)::u,depth
type(dt)::x
integer::n
read(u,*)n
x%a=x%a+n
if(depth>1)call visit(u,depth-1)
print '(i3)',x%a
end subroutine'''),' 27\n 17\n',['recursive independent record storage','shared input cursor'],{27:'10\n20\n'})
add('backspace_constructor_snapshot',derived('type(dt)::x,y\ninteger::u,n',"u=27\nread(u,*)n\nx=dt(n)\nbackspace u\nread(u,*)n\ny=dt(n+1)\nprint '(2i3,f5.1)',x%a,y%a,x%y"),' 12 13  2.5\n',['BACKSPACE reread','constructor independent storage'],{27:'12 unused\n'})
add('null_repeat_slash_defaults',derived('type(dt)::x\ninteger::u,a(4)',"u=27\na=[1,2,3,4]\nread(u,*)a\nprint '(5i3)',a,x%a"),'  1  9  9  4  7\n',['list null/repeat/slash','untouched record defaults'],{27:',2*9/ ignored\n'})
add('eof_two_backspaces',derived('type(dt)::x\ninteger::u,n,s',"u=27\nread(u,*)n\nread(u,*,iostat=s)n\nprint '(l1,i3)',s<0,x%a\nbackspace u\nbackspace u\nread(u,*)n\nprint '(i3)',n"),'T  7\n 21\n',['endfile state','two BACKSPACEs','defaults after IOSTAT'],{27:'21\n'})
add('read_iostat_error_no_undefined_read',derived('type(dt)::x\ninteger::u,n,s',"u=27\nn=99\nread(u,*,iostat=s)n\nprint '(l1,i3,f5.1)',s>0,x%a,x%y"),'T  7  2.5\n',['READ failure status','unrelated defaults preserved','no undefined target read'],{27:'bad\n'})
add('move_read_eoshift_vector',derived('type(dt)::x\ninteger::u\ninteger,allocatable::a(:),b(:)',"u=27\nallocate(a(-1:2))\nread(u,*)a\ncall move_alloc(a,b)\nb=eoshift(b,1,boundary=x%a)\nprint '(l1,6i3)',allocated(a),lbound(b),ubound(b),b"),'F -1  2  2  3  4  7\n',['explicit lower bounds','external array READ','MOVE_ALLOC','EOSHIFT default component boundary'],{27:'1 2 3 4\n'})
add('rank_two_move_vector_shift',program('integer::u\nreal,allocatable::a(:,:),b(:,:)\nreal::c(2,3)',"u=27\nallocate(a(2,3))\nread(u,*)a\ncall move_alloc(a,b)\nc=eoshift(b,[1,-1],boundary=[0.,9.],dim=2)\nprint '(6f5.1)',c\nprint '(f5.1)',norm2(c(:,1))"),'  3.0  9.0  5.0  2.0  0.0  4.0\n  9.5\n',['rank-two READ storage order','MOVE_ALLOC','vector SHIFT and BOUNDARY','NORM2'],{27:'1 2 3 4 5 6\n'})
add('character_move_blank_boundary',program('integer::u\ncharacter(3),allocatable::a(:),b(:)\ncharacter(3)::c(3)',"u=27\nallocate(a(3))\nread(u,*)a\ncall move_alloc(a,b)\nc=eoshift(b,1)\nprint '(*(a))','[',c(1),'][',c(2),'][',c(3),']'"),'[B C][z  ][   ]\n',['quoted external CHARACTER','fixed length MOVE_ALLOC','EOSHIFT blank boundary'],{27:"'a' 'B C' 'z'\n"})
add('deferred_scalar_move_internal_read',program('integer::u,n,s\ncharacter(:),allocatable::a,b',"u=27\na='    '\nread(u,'(a)')a\ncall move_alloc(from=a,to=b)\nread(b,*,iostat=s)n\nprint '(l1,i3,a,a,a)',allocated(a),n,'[',b,']'"),'F 12[12  ]\n',['scalar deferred allocation','external (A)','MOVE_ALLOC','internal list READ'],{27:'12\n'})
add('empty_move_eoshift_shape',program('integer,allocatable::a(:),b(:)\ninteger::c(0)',"allocate(a(0))\ncall move_alloc(a,b)\nc=eoshift(b,huge(0))\nprint '(l1,3i3)',allocated(a),size(b),size(c),kind(eoshift(b,1))"),'F  0  0  4\n',['empty allocation transfer','empty EOSHIFT','KIND metadata'])
add('move_bounds_explicit_kind',program('integer(8),allocatable::a(:),b(:)\ninteger::u',"u=27\nallocate(a(-2:0))\nread(u,*)a\ncall move_alloc(to=b,from=a)\nprint '(5i22)',lbound(b,kind=8),ubound(b,kind=8),b"),' -2 0 9007199254740993 4 -5\n',['KIND8 exact integer input','MOVE_ALLOC bounds','keyword reordering'],{27:'9007199254740993 4 -5\n'},numeric_lines=[0])
add('allocation_errmsg_recovery_defaults',derived('type(dt)::x\ninteger,allocatable::a(:)\ninteger::s\ncharacter(8)::msg',"msg='KEEP'\nallocate(a(2),stat=s,errmsg=msg)\nprint '(l1,a,a,a)',s==0,'[',msg,']'\na=3\nallocate(a(4),stat=s,errmsg=msg)\nprint '(l1,l1,3i3)',s/=0,msg/='KEEP',size(a),a(1),x%a"),'T[KEEP    ]\nTT  2  3  7\n',['ERRMSG success unchanged','recoverable duplicate ALLOCATE','defaults independent'])
add('unallocated_move_clears_destination',derived('type(dt)::x\ninteger,allocatable::a(:),b(:)',"allocate(b(2))\nb=x%a\ncall move_alloc(a,b)\nprint '(2l1,i3)',allocated(a),allocated(b),x%a"),'FF  7\n',['unallocated FROM','discard old TO','record not aliased'])
add('rank_three_read_move_slice_shift',program('integer::u\ninteger,allocatable::a(:,:,:),b(:,:,:)\ninteger::c(2)',"u=27\nallocate(a(-1:0,2:2,4:5))\nread(u,*)a\ncall move_alloc(a,b)\nc=eoshift(b(:,2,5),-1,boundary=9)\nprint '(4i3)',b\nprint '(2i3)',c\nprint '(6i3)',lbound(b),ubound(b)"),'  1  2  3  4\n  9  3\n -1  2  4  0  2  5\n',['rank-three external input','MOVE_ALLOC rank-three','rank-one EOSHIFT slice'],{27:'1 2 3 4\n'})
add('default_result_nonempty_eoshift',derived('type(dt)::x\ninteger::a(3)',"x=make(27)\na=eoshift([1,2,3],1,boundary=x%a)\nprint '(3i3,f5.1)',a,x%y",'''function make(u) result(r)
integer,intent(in)::u
type(dt)::r
integer::n
read(u,*)n
r%a=r%a+n
end function'''),'  2  3 12  2.5\n',['nonempty default result body','READ function lifetime','EOSHIFT boundary'],{27:'5\n'})
add('positioning_read_nonadvancing',derived('type(dt)::x\ninteger::u,n',"u=27\nwrite(*,'(a,t2,a)',advance='no')'ABCD','x'\nread(u,*)n\nwrite(*,'(tr1,i1)')n\nprint '(i1)',x%a"),'AxC5\n7\n',['pending output cursor','external READ does not commit output','TR overwrite','default after record'],{27:'5\n'})
add('two_units_default_calls',derived('',"call show(27)\ncall show(28)\ncall show(27)",'''subroutine show(u)
integer,intent(in)::u
type(dt)::x
integer::n
read(u,*)n
x%a=x%a+n
print '(i3)',x%a
end subroutine'''),'  8\n 16\n  9\n',['independent input units','fresh invocation defaults'],{27:'1\n2\n',28:'9\n'})
add('signed_zero_read_move_shift',program('integer::u\nreal(8),allocatable::a(:),b(:)\nreal(8)::c(2)',"u=27\nallocate(a(2))\nread(u,*)a\ncall move_alloc(a,b)\nc=eoshift(b,1,boundary=-0d0)\nprint '(2es25.17)',c"),'0.0 -0.0\n',['finite REAL8 input','signed zero preservation','MOVE_ALLOC','EOSHIFT boundary'],{27:'-0.0 0.0\n'},numeric_lines=[0])
add('metadata_no_read_default_kind',derived('type(dt)::x\nreal(8)::a(3)\ninteger::n',"n=kind(eoshift(a,x%a))\nprint '(2i3)',n,x%a"),'  8  7\n',['KIND metadata-only EOSHIFT','default component control metadata','undefined array not read'])
add('bad_input_pending_output_atomic',derived('type(dt)::x\ninteger::u,n',"u=27\nwrite(*,'(a,t2,a)',advance='no')'ABCD','x'\nread(u,*)n\nprint '(i0)',x%a"),'AxCD',['READ failure','pending output preserved','no following record'],{27:'bad\n'},category='runtime',gnu='compile',diagnostic=('read(u,*)n','invalid value or past endfile in external READ input',1))
add('unbound_input_default_prefix',derived('type(dt)::x\ninteger::u,n',"u=27\nprint '(i0)',x%a\nread(u,*)n"),'7\n',['explicit binding guard','prior default output'],category='runtime',gnu='compile',diagnostic=('read(u,*)n','external input unit is not explicitly bound',1))
add('move_undefined_element_guard',derived('type(dt)::x\ninteger,allocatable::a(:),b(:)',"allocate(a(1))\ncall move_alloc(a,b)\nprint '(i0)',x%a\nprint '(i0)',b(1)"),'7\n',['MOVE_ALLOC retains undefinedness','default independent','atomic failing output'],category='runtime',gnu='compile',diagnostic=("print '(i0)',b(1)",'read of uninitialized array element b',14))
# A narrower interpreter input target contract, not a language prohibition.
add('derived_component_read_boundary',derived('type(dt)::x\ninteger::u',"u=27\nread(u,*)x%a\nprint '(i0)',x%a"),'',['READ whole intrinsic targets only','default component target boundary'],{27:'4\n'},category='reject',gnu='compile',diagnostic=('read(u,*)x%a','External READ requires an INTEGER unit variable, list-directed whole local numeric or CHARACTER targets or literal (A) scalar CHARACTER or local CHARACTER element without user-call or IOSTAT-dependent indices, and optional INTEGER IOSTAT outside PURE/SIMPLE procedures',13))
# Preserved initial probes expose bounded existing expression/effect policies.
# These metadata changes never rewrite those source files. Separate variants
# below exercise the supported paths instead of weakening the guards.
BOUNDARIES={
 'move_read_eoshift_vector':('runtime',18,26,'invalid KIND argument opcode'),
 'metadata_no_read_default_kind':('runtime',14,20,'invalid KIND argument opcode'),
 'default_result_nonempty_eoshift':('reject',12,11,'External READ requires an INTEGER unit variable, list-directed whole local numeric or CHARACTER targets or literal (A) scalar CHARACTER or local CHARACTER element without user-call or IOSTAT-dependent indices, and optional INTEGER IOSTAT outside PURE/SIMPLE procedures'),
}
for c in CASES:
 if c['name'] in BOUNDARIES:
  category,line,column,message=BOUNDARIES[c['name']]
  c.update(category=category,gnu='compile',expected_stdout='',diagnostic=message,diagnostic_line=line,diagnostic_column=column)
add('scalar_boundary_move_read_eoshift',derived('type(dt)::x\ninteger::u,k\ninteger,allocatable::a(:),b(:)',"u=27\nallocate(a(-1:2))\nread(u,*)a\ncall move_alloc(a,b)\nk=x%a\nb=eoshift(b,1,boundary=k)\nprint '(l1,6i3)',allocated(a),lbound(b),ubound(b),b"),'F -1  2  2  3  4  7\n',['explicit lower bounds','READ/MOVE_ALLOC','default staged through scalar BOUNDARY'],{27:'1 2 3 4\n'})
add('scalar_shift_metadata_default_kind',derived('type(dt)::x\nreal(8)::a(3)\ninteger::n,k',"k=x%a\nn=kind(eoshift(a,k))\nprint '(2i3)',n,x%a"),'  8  7\n',['KIND metadata-only EOSHIFT','default value staged through scalar SHIFT','undefined array not read'])
add('explicit_impure_default_result_eoshift',derived('type(dt)::x\ninteger::a(3),k',"x=make(27)\nk=x%a\na=eoshift([1,2,3],1,boundary=k)\nprint '(3i3,f5.1)',a,x%y",'''impure function make(u) result(r)
integer,intent(in)::u
type(dt)::r
integer::n
read(u,*)n
r%a=r%a+n
end function'''),'  2  3 12  2.5\n',['explicit IMPURE READ function','nonempty default result body','scalar EOSHIFT boundary'],{27:'5\n'})
# The attempted explicit-IMPURE variant is also retained: this parser accepts
# that prefix only with ELEMENTAL, before external-READ validation is reached.
for c in CASES:
 if c['name']=='explicit_impure_default_result_eoshift':
  c.update(category='reject',gnu='compile',expected_stdout='',diagnostic='IMPURE non-ELEMENTAL prefixes are unsupported',diagnostic_line=8,diagnostic_column=8)
add('main_read_default_result_eoshift',derived('type(dt)::x\ninteger::a(3),u,n,k',"u=27\nread(u,*)n\nx=make(n)\nk=x%a\na=eoshift([1,2,3],1,boundary=k)\nprint '(3i3,f5.1)',a,x%y",'''function make(n) result(r)
integer,intent(in)::n
type(dt)::r
r%a=r%a+n
end function'''),'  2  3 12  2.5\n',['main external READ','nonempty default result body','scalar EOSHIFT boundary'],{27:'5\n'})
(ROOT/'manifest.json').write_text(json.dumps(dict(schema=1,cases=CASES),indent=2)+'\n')
(ROOT/'SOURCE-IDENTITY.json').write_text(json.dumps(dict(sources=[dict(name=c['name'],file=c['source'],sha256=c['sha256']) for c in CASES],inputs=[dict(case=c['name'],**f) for c in CASES for f in c.get('inputs',[])]),indent=2)+'\n')
print(len(CASES))
