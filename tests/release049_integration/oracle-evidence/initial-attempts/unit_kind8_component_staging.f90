module m
implicit none
type::box
integer::a,b=2
character(4)::s="Wide"
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer(8)::u,n
u=int(output_unit,8)
n=int(x%b,8)
write(u,"(a,/,i0)")x%s,leadz(n)
end program
