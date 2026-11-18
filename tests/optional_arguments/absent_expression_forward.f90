module invalid_optional
implicit none
contains
subroutine required(a)
integer,intent(in) :: a
print *,a
end subroutine
subroutine run(b)
integer,optional,intent(inout) :: b
call required(b+1)
end subroutine
end module
program invalid_optional_test
use invalid_optional
implicit none
integer :: v
call run()
end program
