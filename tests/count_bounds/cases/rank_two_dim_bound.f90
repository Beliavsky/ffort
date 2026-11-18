module m
implicit none
contains
subroutine work(x)
logical,intent(in)::x(:,:)

integer::a(count(x,1))

a=7
end subroutine
end module
program p
use m
implicit none
logical::v(1,1)=.true.
call work(v)
end program
