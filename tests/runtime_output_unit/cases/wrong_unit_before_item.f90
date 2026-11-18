program p
use iso_fortran_env,only:output_unit
implicit none
integer::u,x
u=output_unit+1
write(u,"(i0)")x

end program
