module m
implicit none
type::box
integer::n=0
character(0)::s
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
integer::u
x%s="discard"
u=output_unit
write(u,"(a,/,i0)")"["//repeat(x%s,3)//"]",len(x%s)
end program
