module io_names
use iso_fortran_env,only:u=>output_unit
implicit none
contains
subroutine show()
write(u,'(a,i0)') 'module-host=',u
end subroutine
end module
program p
use io_names,only:show
implicit none
call show()
end program
