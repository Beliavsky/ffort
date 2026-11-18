module m
implicit none
contains
subroutine fill(x,n)
character(*),intent(out)::x(:)
integer,intent(out)::n
character(len(x))::scratch(0)
n=len(x)+len(scratch)
x="z"
end subroutine
end module m
program test
use m
implicit none
character(7) :: a(0)
integer :: n
call fill(a,n)
print *,n,size(a)
end program test
