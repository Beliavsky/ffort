module m
implicit none
contains
function f(x) result(a)
logical,intent(in)::x(:,:)

integer::a(count(x),2)

a=7
end function
end module
program p
use m
implicit none
logical::v(2,2)
v(:,1)=[.true.,.false.]
v(:,2)=[.true.,.true.]
print *,f(v)
print *,size(f(v))
end program
