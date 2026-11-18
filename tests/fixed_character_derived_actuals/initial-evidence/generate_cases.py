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
p=R/'source/three_features.f90';cases.append(dict(name='original_three_features',source='source/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage='success',gnu='run',expected='>03>06:0614\n',diagnostic=None,integer_records=[]))
(R/'manifest.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');print(len(cases),'cases')
