module m
implicit none
contains
subroutine work(x)
integer(8),intent(in)::x(:)

integer::a(count(x>2147483647_8,kind=8))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([0_8,2147483648_8,9223372036854775807_8])
end program
