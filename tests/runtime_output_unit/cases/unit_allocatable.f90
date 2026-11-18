program p
use iso_fortran_env,only:output_unit
implicit none
integer,allocatable::u
allocate(u)
u=output_unit
write(u,"(a)")"bad"

end program
