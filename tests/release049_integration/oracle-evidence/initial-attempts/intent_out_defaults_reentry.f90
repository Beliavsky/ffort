module m
implicit none
type::box
integer::a,b=8
character(3)::s="cat"
end type
contains
subroutine reset(x,n)
type(box),intent(out)::x
integer,intent(in)::n
if(x%b/=8.or.x%s/="cat")error stop "out defaults"
x%a=n
x%s="Q"
end subroutine
end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer::u,n
x%s="old"
call reset(x,2)
call reset(x,3)
n=x%b
u=output_unit
write(u,"(a,/,2i3)")x%s,x%a,leadz(n)
end program
