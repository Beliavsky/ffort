module m
implicit none
contains
subroutine inspect(x)
character(2),intent(in)::x(:)
print *,len(x),x(1)//"|",x(2)//"|"
end subroutine
end module m
program test
use m
implicit none
character(5) :: a(2)=["abcde","fghij"]
call inspect(a)
end program test
