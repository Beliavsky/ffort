program p
use iso_fortran_env,only:output_unit
implicit none

call q(int(output_unit,kind=8))
contains
subroutine q(u)
integer(8),intent(in)::u
write(u,"(a)")"PASS"
end subroutine
end program
