module units
use iso_fortran_env,only:output_unit
contains
subroutine outer()
integer::u
u=output_unit
call inner()
contains
subroutine inner()
write(u,"(a)")"PASS"
end subroutine
end subroutine
end module
program p
use units
call outer()
end program
