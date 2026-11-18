module m
implicit none
type::box
character(3)::s="xy"
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
character(5)::buffer
integer::u
write(buffer,"(a,:,/)")x%s
u=output_unit
write(u,"(a,/,i0)")"["//buffer//"]",leadz(2)
end program
