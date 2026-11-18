module m
implicit none
type::box
integer::a,b=8,c
character(3)::s="Ab",t
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer::n,u
x%a=1
x%c=3
x%t="Q"
n=x%b
u=output_unit
write(u,"(a,/,3(i0,1x))")repeat(x%s,2),x%a,leadz(n),x%c
end program
