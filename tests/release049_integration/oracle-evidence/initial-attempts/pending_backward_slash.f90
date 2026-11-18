module m
implicit none
type::box
character(5)::s="ABCDE"
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
write(u,"(a)",advance="no")x%s
write(u,"(tl2,a,/)",advance="no")"X"
write(u,"(a)")"Z"
end program
