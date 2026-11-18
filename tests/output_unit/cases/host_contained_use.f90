program p
use iso_fortran_env,only:u=>output_unit
implicit none
call show()
contains
subroutine show()
write(u,'(a,i0)') 'host=',u
end subroutine
end program
