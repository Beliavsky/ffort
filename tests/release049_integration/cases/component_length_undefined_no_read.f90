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
write(u,"(i0,/,a)")len(x%s),repeat("_",len(x%s))
end program
