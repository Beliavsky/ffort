module m
implicit none
type::box
character(3)::s="ABC"
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
character(8)::buffer
integer::u
u=output_unit
write(u,"(a)")"SAFE"
write(buffer,"(a,/)")x%s
end program
