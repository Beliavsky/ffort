module invalid_optional
implicit none
contains
subroutine run(x)
integer,optional :: x
end subroutine
end module
program invalid_optional_test
use invalid_optional
implicit none
integer :: v
call run()
end program
