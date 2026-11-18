module invalid_optional
implicit none
contains
subroutine run(b)
integer,optional,intent(in) :: b
print *,b
end subroutine
end module
program invalid_optional_test
use invalid_optional
implicit none
integer :: v
call run(v)
end program
