module m
implicit none
contains
subroutine work(x)
logical,intent(in)::x(:)

integer::a(count(kind=kind(1_8),dim=1,mask=x))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([.true.,.false.,.true.])
end program
