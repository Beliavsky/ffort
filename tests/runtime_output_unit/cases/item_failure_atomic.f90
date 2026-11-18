program p
use iso_fortran_env,only:output_unit
implicit none
integer::u,x
u=output_unit
write(u,"(a,i0)")"no leak",x

end program
