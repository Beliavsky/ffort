module m
implicit none
contains
subroutine inner(x)
character(*),intent(out)::x(:)
x="a"
end subroutine
subroutine outer(x)
character(*),intent(out)::x(:)
call inner(x)
end subroutine
end module m
program test
use m
implicit none
character(5)::a(2)
call outer(a)
print *,a(1)//"|",a(2)//"|"
end program test
