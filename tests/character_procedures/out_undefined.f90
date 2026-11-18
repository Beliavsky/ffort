module m
implicit none
contains
subroutine fill(x,n)
character(*),intent(out)::x(:)
integer,intent(out)::n
n=len(x)
x="z"
end subroutine
end module m
program test
use m
implicit none
character(4) :: a(2)
integer :: n
call fill(a,n)
print *,n,a(1)//"|",a(2)//"|"
end program test
