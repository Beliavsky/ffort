program p
use iso_fortran_env,only:output_unit
implicit none
integer(2)::u
u=6
write(u,"(a)")"bad"

end program
