program p
use iso_fortran_env,only:output_unit
implicit none

call q(output_unit)
contains
pure subroutine q(u)
integer,intent(in)::u
write(u,"(a)")"bad"
end subroutine
end program
