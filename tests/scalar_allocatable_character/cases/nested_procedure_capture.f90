module m
implicit none
contains
subroutine outer()
character(:),allocatable::x
if(allocated(x)) error stop 1
x='a'
call inner()
if(x/='ab') error stop 2
contains
subroutine inner()
x=x//'b'
end subroutine
end subroutine
end module
program p
use m
implicit none
call outer()
call outer()
end program
