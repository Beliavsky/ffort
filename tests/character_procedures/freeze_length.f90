module m
implicit none
contains
subroutine work(n,a)
integer,intent(inout)::n
character(*),intent(out)::a(:)
character(n)::tmp(size(a))
n=7
tmp="abcdef"
a=tmp
end subroutine
end module m
program test
use m
implicit none
integer :: n
character(3) :: a(1)
n=3
call work(n,a)
print *,n,a(1)//"|"
end program test
