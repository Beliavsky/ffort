from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent;cases=[]
module='''module m
implicit none
type::box
 integer::x=3
contains
 procedure::text
end type
contains
character(2) function text(this) result(s)
 class(box),intent(in)::this
 write(s,'(i2.2)')this%x
end function
character(2) function plain(b) result(s)
 type(box),intent(in)::b
 write(s,'(i2.2)')b%x
end function
character(2) function number(n) result(s)
 integer,intent(in)::n
 write(s,'(i2.2)')n
end function
function make(n) result(b)
 integer,intent(in)::n
 type(box)::b
 b=box(n)
end function
recursive function chain(n) result(b)
 integer,intent(in)::n
 type(box)::b
 if(n==0)then
  b=box(3)
 else
  b=chain(n-1)
 endif
end function
character(2) function forbidden(b) result(s)
 type(box),intent(in)::b
 error stop 77
 s='NO'
end function
end module
program p
use m
implicit none
type(box)::b,c
character(2)::a(2)
integer::i
b=box(3)
c=box(6)
'''
def add(name,body,out):
 p=R/'cases'/(name+'.f90');p.write_text(module+body+'\nend program\n');cases.append(dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage='success',gnu='run',expected=out,diagnostic=None,integer_records=[]))
add('bound_direct',"a=[b%text(),c%text()]\nwrite(*,'(2a)')a",'0306\n')
add('bound_nested',"a=[(b%text(),i=1,2)]\nwrite(*,'(2a)')a",'0303\n')
add('bound_zero_trip_len',"write(*,'(i0)')len([(b%text(),i=1,0)])",'2\n')
add('plain_variable',"a=[plain(b),plain(c)]\nwrite(*,'(2a)')a",'0306\n')
add('plain_constructor',"a=[plain(box(3)),plain(box(6))]\nwrite(*,'(2a)')a",'0306\n')
add('plain_default_constructor',"a=[plain(box()),plain(box())]\nwrite(*,'(2a)')a",'0303\n')
add('plain_derived_result',"a=[plain(make(3)),plain(make(6))]\nwrite(*,'(2a)')a",'0306\n')
add('plain_recursive_result',"a=[plain(chain(2)),plain(chain(3))]\nwrite(*,'(2a)')a",'0303\n')
add('numeric_component',"a=[number(b%x),number(c%x)]\nwrite(*,'(2a)')a",'0306\n')
add('len_no_execution',"write(*,'(i0)')len([forbidden(b)])",'2\n')
add('zero_trip_no_execution',"write(*,'(i0,1x,i0)')len([(forbidden(b),i=1,0)]),size([(forbidden(b),i=1,0)])",'2 0\n')
def raw(name,text,out='2\n',stage='success',gnu='run'):
 p=R/'cases'/(name+'.f90');p.write_text(text);cases.append(dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage=stage,gnu=gnu,expected=out,diagnostic=None,integer_records=[]))
for name,expr in [('optional_absent_len','len([f(b)])'),('optional_absent_zero_trip','len([(f(b),i=1,0)])')]:
 raw(name,'module z\ntype::box\ninteger::x\nend type\ncontains\ncharacter(2) function f(b) result(s)\ntype(box),optional,intent(in)::b\nerror stop 77\ns="NO"\nend function\nsubroutine probe(b)\ntype(box),optional,intent(in)::b\ninteger::i\nwrite(*,"(i0)")'+expr+'\nend subroutine\nend module\nprogram p\nuse z\ncall probe()\nend program\n')
raw('partial_uninitialized_len','module z\ntype::box\ninteger::x,y\nend type\ncontains\ncharacter(2) function f(b) result(s)\ntype(box),intent(in)::b\nerror stop 77\ns="NO"\nend function\nend module\nprogram p\nuse z\ntype(box)::b\nb%x=3\nwrite(*,"(i0)")len([f(b)])\nend program\n')
raw('real_component_conversion','module z\ntype::box\nreal::x\nend type\ncontains\ncharacter(2) function f(b) result(s)\ntype(box),intent(in)::b\nif(b%x/=3.0)stop 1\ns="OK"\nend function\nend module\nprogram p\nuse z\nwrite(*,"(a)")[f(box(3))]\nend program\n','OK\n')
raw('direct_derived_kind_boundary','program p\ntype::box\ninteger::x\nend type\ntype(box)::b\nprint *,kind(b)\nend program\n','',stage='reject',gnu='reject')
for name,expr in [('optional_integer_absent_len','len([f(n)])'),('optional_integer_absent_zero_trip','len([(f(n),i=1,0)])')]:
 raw(name,'module z\ncontains\ncharacter(2) function f(n) result(s)\ninteger,optional,intent(in)::n\nerror stop 77\ns="NO"\nend function\nsubroutine probe(n)\ninteger,optional,intent(in)::n\ninteger::i\nwrite(*,"(i0)")'+expr+'\nend subroutine\nend module\nprogram p\nuse z\ncall probe()\nend program\n')
raw('module_derived_kind_boundary','module z\ntype::box\ninteger::x\nend type\nend module\nprogram p\nuse z\ntype(box)::b\nprint *,kind(b)\nend program\n','',stage='reject',gnu='reject')
for c in cases:
 if c['name'] in ['optional_absent_len','optional_absent_zero_trip']:
  c['stage']='reject';c['gnu_expected']=c['expected'];c['expected']='';c['diagnostic']='7:33: OPTIONAL supports INTEGER, REAL, LOGICAL and CHARACTER dummies only';c['reason']='GNU-valid optional derived dummy is outside existing parser subset.'
 if c['name']=='direct_derived_kind_boundary':
  c['diagnostic']='2:5: Expected (, found ::';c['reason']='Local derived declaration subset boundary; module variant separately reaches KIND restriction.'
for c in cases:
 if c['name']=='module_derived_kind_boundary':c['diagnostic']='0:0: FortFront adapter: KIND type or argument count differs'
p=R/'source/three_features.f90';cases.append(dict(name='original_three_features',source='source/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage='success',gnu='run',expected='>03>06:0614\n',diagnostic=None,integer_records=[]))
(R/'manifest.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');print(len(cases),'cases')
