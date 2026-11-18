program p

implicit none
call show()
contains
subroutine show()
use iso_fortran_env,only:u=>output_unit
implicit none
write(u,'(a,i0)') 'local=',u
end subroutine
end program
