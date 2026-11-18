module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x(:)
integer,parameter::threshold=0
integer::a(count(x>threshold))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([-1,0,2])
end program
