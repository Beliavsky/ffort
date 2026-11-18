module m
contains
subroutine consume(v)
real,intent(in)::v(:,:)
print *,v
end subroutine
end module
program main
use m
implicit none
real::x(2,2)
x=1
call consume(x([2,1],:))
end program
