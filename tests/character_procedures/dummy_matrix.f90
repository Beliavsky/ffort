module m
implicit none
contains
subroutine mutate(x,n)
character(*),intent(inout)::x(-2:,0:)
integer,intent(out)::n
n=len(x)+size(x)+lbound(x,1)+lbound(x,2)
x(-1,1)="abcde"
x(-2,0)="q"
end subroutine
end module m
program test
use m
implicit none
character(3) :: a(-1:0,3:4)
integer :: n
a="x"
call mutate(a,n)
print *,n,a(0,4)//"|",a(-1,3)//"|"
end program test
