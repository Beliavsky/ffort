module io_names
use iso_fortran_env,only:u=>output_unit
implicit none
private
public::show
contains
subroutine show()
write(u,'(a)') 'private'
end subroutine
end module
program p
use io_names,only:show
implicit none
call show()
end program
