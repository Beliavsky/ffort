program p
use iso_fortran_env,only:output_unit
implicit none
integer(8)::u
u=huge(u)
write(u,"(a)")"bad"

end program
