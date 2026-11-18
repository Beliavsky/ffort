module m
implicit none
type::box
integer::n=1
character(3)::s="fmt"
end type
contains

end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x
integer::u,n
character(20)::fmt
fmt=repeat("(a,/,i0)",1)
u=output_unit
n=x%n
write(u,fmt=fmt)x%s,leadz(n)
end program
