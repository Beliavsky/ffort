module units
use iso_fortran_env,only:output_unit
integer::u
contains
subroutine q()
u=output_unit
write(u,"(a)")"PASS"
end subroutine
end module
program p
use units
call q()
end program
