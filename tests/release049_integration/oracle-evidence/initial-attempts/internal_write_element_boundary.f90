module m
implicit none
type::box
integer::a,b=2
character(3)::s="ABC"
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
character(8)::buffer(2)
integer::u
write(buffer(1),"(a,i0)")x%s,x%b
u=output_unit
write(u,"(a)")buffer(1)
end program
