program p
use iso_fortran_env,only:output_unit
implicit none
integer,target::x
integer,pointer::u
x=output_unit
u=>x
write(u,"(a)")"bad"

end program
