module m
implicit none
contains
subroutine work(x,n,enabled)
integer,intent(in)::x(:),n
logical,intent(in)::enabled
integer::a(count((x>n).and.enabled))
a=1
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([1,3,4],2,.true.)
call work([1,3,4],2,.false.)
end program
