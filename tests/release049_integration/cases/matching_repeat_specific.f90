module m
implicit none
type::box
character(3)::s="Ab"
end type
interface repeat
 module procedure user_repeat
end interface
contains
character(4) function user_repeat(string,ncopies) result(answer)
character(*),intent(in)::string
integer,intent(in)::ncopies
answer="USER"
end function
end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer::u
u=output_unit
write(u,"(a,/,i0)")repeat(ncopies=2,string=x%s),leadz(1)
end program
