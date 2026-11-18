program p
use iso_fortran_env,only:output_unit
implicit none

call q()
contains
subroutine q(u)
integer,optional,intent(in)::u
write(u,"(a)")"bad"
end subroutine
end program
