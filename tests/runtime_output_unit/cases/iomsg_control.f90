program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
character(20)::msg
u=output_unit
write(u,"(a)",iomsg=msg)"bad"

end program
