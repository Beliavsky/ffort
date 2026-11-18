module first
implicit none
private
public::box,operator(+)
type::box
integer::value
end type
interface operator(+)
module procedure add_box
end interface
contains
function add_box(a,b) result(c)
type(box),intent(in)::a,b
type(box)::c
c%value=a%value+b%value
end function
end module
module second
use first,only:box,operator(+)
implicit none
private
public::probe
contains
integer function probe(x) result(y)
integer,intent(in)::x
type(box)::a,b,c
a=box(x)
b=box(3)
c=a+b
y=c%value
end function
end module
program main
use second,only:probe
implicit none
print *,probe(7)
end program
