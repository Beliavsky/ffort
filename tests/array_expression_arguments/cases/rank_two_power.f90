module m
implicit none
integer,parameter::dp=kind(1d0)
contains
function probe(v) result(y)
real(dp),intent(in)::v(:,:)
real(dp)::y
y=sum(v)/size(v)
end function
end module
program p
use m
implicit none
real(dp)::a(-1:0,4:5)=2d0

print *,probe(a**2)
end program
