module m
implicit none
contains
subroutine work(x)
logical,intent(in)::x(:)

integer::a(count(x.eqv.(count(x)>1)))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([.true.,.false.,.true.])
end program
