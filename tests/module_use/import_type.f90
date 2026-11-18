module first
implicit none
type::box
integer::value
end type
end module
module second
use first,only:box
implicit none
private
public::probe
contains
integer function probe(x) result(y)
integer,intent(in)::x
 type(box)::b
b=box(x)
y=b%value
end function
end module
program main
use second,only:probe
implicit none
print *,probe(7)
end program
