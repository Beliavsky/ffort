module m
implicit none
contains
pure elemental real(8) function transform(x) result(y)
real(8),intent(in)::x
y=tanh(x)+sinh(x)/cosh(x)
end function
subroutine apply(x,y)
real(8),intent(in)::x(:,:)
real(8),intent(out)::y(:,:)
y=cosh(x=x)+sinh(x)
end subroutine
end module
program procedures
use m
implicit none
real(8)::a(2,2),b(2,2)
a(:,1)=[-0.5d0,0.0d0]
a(:,2)=[0.125d0,0.5d0]
call apply(a,b)
print *,transform(a),b
end program
