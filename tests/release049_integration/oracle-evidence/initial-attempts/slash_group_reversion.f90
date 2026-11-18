module m
implicit none
type::box
character(2)::s="Ab"
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer::u,n
u=output_unit
n=1
write(u,"(a,/,i0)")x%s,leadz(n),repeat("Q",2),leadz(0)
end program
