module m
implicit none
contains
subroutine work(x)
real(8),intent(in)::x(:)

integer::a(count(abs(x)>1.0_8.and.x<3.0_8))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([-2.0_8,0.0_8,2.0_8,4.0_8])
end program
