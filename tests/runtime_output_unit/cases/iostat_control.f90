program p
use iso_fortran_env,only:output_unit
implicit none
integer::u,ios
u=output_unit
write(u,"(a)",iostat=ios)"bad"

end program
