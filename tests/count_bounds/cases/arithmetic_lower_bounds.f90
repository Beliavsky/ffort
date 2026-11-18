module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x(:)

integer::a(-count(x<0):count(x>0)-1)

a=7
print *,lbound(a,1),ubound(a,1),size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([-4,-2,0,2,3])
end program
