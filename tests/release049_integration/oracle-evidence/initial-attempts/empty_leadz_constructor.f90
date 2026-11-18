program p
use iso_fortran_env, only: output_unit
implicit none
integer(8)::a(0)
integer::b(0),u
character(:),allocatable::s
b=leadz(a)
s=repeat("x",size(b))
u=output_unit
write(u,"(a,/,i0)")"["//s//"]",kind(b)
end program
