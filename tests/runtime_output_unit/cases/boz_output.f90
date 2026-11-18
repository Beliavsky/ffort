program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
u=output_unit
write(u,"(z2.2)")255

end program
