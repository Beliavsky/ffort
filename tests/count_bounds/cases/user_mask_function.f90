module m
implicit none
contains
pure function mask(x) result(y)
logical,intent(in)::x(:)
logical::y(size(x))
y=x
end function
subroutine work(x)
logical,intent(in)::x(:)
integer::a(count(mask(x)))
a=1
end subroutine
end module
program p
use m
implicit none
call work([.true.])
end program
