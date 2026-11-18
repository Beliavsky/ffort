program p
use iso_fortran_env, only: output_unit
implicit none
integer(8)::a(3)
integer::b(3),i,u
a=[(2_8**i,i=0,2)]
b=leadz(a)+leadz(1_8)
u=output_unit
write(u,"(3i4,/,i0)")b,kind(leadz(a))
end program
