module m
implicit none

contains
subroutine first(x)
real, intent(in) :: x
call second(x*2)
print *,x
end subroutine first
subroutine second(x)
real, intent(in) :: x
print *,x
end subroutine second
end module m
program main
use m
implicit none

call first(3.0)
end program main
