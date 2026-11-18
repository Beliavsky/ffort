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
integer::u
u=output_unit
write(u,"(a)",advance="no")x%s
write(u,"(/,t3,a)",advance="no")repeat("D",2)
write(u,"(a)")"E"
end program
