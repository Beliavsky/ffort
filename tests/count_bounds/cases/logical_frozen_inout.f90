module m
implicit none
contains
subroutine work(x)
logical,intent(inout)::x(:)

integer::a(count(x))

x=.false.
a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
logical::v(3)=[.true.,.false.,.true.]
call work(v)
call work(v)
end program
