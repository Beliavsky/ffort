module m
implicit none
contains
subroutine sub(x)
real, intent(in) :: x
print*,"twice",x," is",2*x
end subroutine sub
end module m

program main
use m
implicit none
call sub(2.3)
end program main
