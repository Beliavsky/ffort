program p

implicit none
call show()
contains
pure subroutine show()
use iso_fortran_env,only:u=>output_unit
write(u,'(a)') 'no'
end subroutine
end program
