module m
implicit none
type::box
integer::n=1
character(3)::s="aB"
end type
interface repeat
 module procedure user_repeat
end interface
contains
integer function user_repeat(n) result(answer)
integer,intent(in)::n
answer=n+100
end function
end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x,y
integer::u
y=x
x%s="Q"
u=output_unit
write(u,"(a,/,i0)")repeat(y%s,2),repeat(7)
end program
