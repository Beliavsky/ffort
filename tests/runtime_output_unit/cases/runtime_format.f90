program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
character(16)::fmt
u=output_unit
fmt="(a,i3)"
write(unit=u,fmt=fmt)"v=",17

end program
