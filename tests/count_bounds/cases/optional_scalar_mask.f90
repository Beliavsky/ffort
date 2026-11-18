module m
implicit none
contains
subroutine work(x,n)
logical,intent(in)::x(:)
logical,intent(in),optional::n
integer::a(count(x.and.n))
a=1
print *,size(a)
end subroutine
end module
program p
use m
implicit none
call work([.true.],.true.)
end program
