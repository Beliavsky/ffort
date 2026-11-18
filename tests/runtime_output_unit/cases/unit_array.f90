program p
use iso_fortran_env,only:output_unit
implicit none
integer::u(1)
u=output_unit
write(u,"(a)")"bad"

end program
