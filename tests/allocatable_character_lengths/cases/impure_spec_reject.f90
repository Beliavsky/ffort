module m
implicit none
contains
integer function width(n) result(v)
integer,intent(in) :: n
v=n+1
end function
subroutine fill(a,n)
integer,intent(in) :: n
character(len=width(n)),allocatable,intent(out) :: a(:)
allocate(a(1))
end subroutine
end module
program p
use m
implicit none
character(4),allocatable :: x(:)
call fill(x,3)
end program
