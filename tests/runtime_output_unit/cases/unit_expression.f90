program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
u=output_unit
write(u+0,"(a)")"bad"

end program
