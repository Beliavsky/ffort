program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
character(10)::fmt
u=output_unit+1
write(u,fmt)"bad"

end program
