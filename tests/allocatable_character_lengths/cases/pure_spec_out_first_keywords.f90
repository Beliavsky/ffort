module m
implicit none
contains
pure integer function width(n) result(v)
integer,intent(in) :: n
v=n+1
end function
subroutine fill(a,n)
integer,intent(in) :: n
character(len=width(width(n=n))),allocatable,intent(out) :: a(:)
allocate(a(1))
a='abcdef'
end subroutine
end module
program p
use m
implicit none
character(5),allocatable :: x(:)
call fill(n=3,a=x)
if (len(x)/=5 .or. x(1)/='abcde') error stop 1
print *,1
end program
