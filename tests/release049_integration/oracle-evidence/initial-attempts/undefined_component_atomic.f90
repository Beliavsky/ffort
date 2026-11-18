module m
implicit none
type::box
integer::a,b=3
character(4)::s
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer::u
u=output_unit
write(u,"(a)")"SAFE"
write(u,"(a,/,i0)")x%s,leadz(1)
end program
