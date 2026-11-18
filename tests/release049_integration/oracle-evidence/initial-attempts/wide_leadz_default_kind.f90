program p
use iso_fortran_env, only: output_unit
implicit none
integer(8)::x(4)
integer::u
x=[0_8,1_8,2147483648_8,-1_8]
u=output_unit
write(u,"(4i3,/,i0)")leadz(x),kind(leadz(x))
end program
