module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x(:)

integer::a(count(x>0))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([-2,0,4]+1)
end program
