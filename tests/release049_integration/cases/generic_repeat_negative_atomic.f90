module m
implicit none
type::box
character(3)::s="ABC"
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
type(box)::x
integer::u,n
u=output_unit
write(u,"(a)",advance="no")"SAFE"
n=-1
write(u,"(a,/,i0)")repeat(x%s,n),repeat(1)
end program
