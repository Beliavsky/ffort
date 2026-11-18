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
integer::v(5)=[1,-1,2,-2,3]
call work(v(5:1:-2))
end program
