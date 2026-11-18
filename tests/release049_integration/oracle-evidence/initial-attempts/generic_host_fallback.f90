module m
implicit none
type::box
character(2)::s="Z "
end type
interface repeat
 module procedure user_repeat
end interface
contains
integer function user_repeat(n) result(answer)
integer,intent(in)::n
answer=n+100
end function
subroutine show(x,u)
type(box),intent(in)::x
integer,intent(in)::u
write(u,"(a,/,i0)")repeat(ncopies=2,string=x%s),repeat(1)
end subroutine
end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer::u
u=output_unit
call show(x,u)
end program
