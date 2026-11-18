program p
use iso_fortran_env,only:output_unit
implicit none

call q(output_unit)
contains
subroutine q(u)
integer,optional,intent(in)::u
write(u,"(a)")"PASS"
end subroutine
end program
