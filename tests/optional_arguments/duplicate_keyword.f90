module invalid_optional
implicit none
contains
subroutine run(a,b)
integer,intent(in) :: a
integer,optional,intent(in) :: b
print *,a
end subroutine
end module
program invalid_optional_test
use invalid_optional
implicit none
integer :: v
call run(1,a=2)
end program
