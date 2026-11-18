program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
integer::x(3)
u=output_unit
x=[1,2,3]
write(u,"(3i2)")x

end program
