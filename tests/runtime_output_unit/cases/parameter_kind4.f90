program p
use iso_fortran_env,only:output_unit
implicit none
integer(4),parameter::u=output_unit
write(u,"(a)")"PASS"

end program
