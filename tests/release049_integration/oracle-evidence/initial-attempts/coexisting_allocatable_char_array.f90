module m
implicit none
type::box
character(2)::s="Hi"
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
character(:),allocatable::a(:)
integer::u
a=[repeat("x",4),repeat("Y",4)]
u=output_unit
write(u,"(a,/,2a)")x%s,a
end program
