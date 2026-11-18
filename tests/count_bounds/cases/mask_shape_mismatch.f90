module m
implicit none
contains
subroutine work(x,y)
logical,intent(in)::x(:),y(:)
integer::a(count(x.and.y))
print *,123
end subroutine
end module
program p
use m
implicit none
call work([.true.,.false.],[.true.])
end program
