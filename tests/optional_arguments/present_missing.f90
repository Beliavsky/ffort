module present_missing_m
implicit none
contains
subroutine run(x)
integer,optional,intent(in) :: x
print *,present()
end subroutine
end module
program present_missing_test
use present_missing_m
implicit none
call run()
end program
