module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x(:)
logical,parameter::flags(3)=[.true.,.false.,.true.]
integer::a(count((x>0).and.flags))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([1,2,3])
end program
