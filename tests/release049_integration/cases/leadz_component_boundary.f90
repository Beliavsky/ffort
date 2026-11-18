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
integer::u
u=output_unit
write(u,"(a,/,i0)")x%s,leadz(x%b)
end program
