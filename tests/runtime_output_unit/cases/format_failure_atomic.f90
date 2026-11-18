program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
character(10)::fmt
u=output_unit
fmt="(Q)"
write(u,fmt)"bad"

end program
