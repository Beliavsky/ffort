module m
implicit none
contains
subroutine work(x)
logical,intent(in)::x(:)

integer::a(count(x))

a=1
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
logical::v(65536)
v=.true.
call work(v)
end program
