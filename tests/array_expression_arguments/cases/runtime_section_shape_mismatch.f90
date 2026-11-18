module m
implicit none
integer,parameter::dp=kind(1d0)
contains
function probe(v) result(y)
real(dp),intent(in)::v(:)
real(dp)::y
y=sum(v)/size(v)
end function
end module
program p
use m
implicit none
real(dp)::x(4)=1d0
integer::n=3,k=4

print *,probe(x(1:n)+x(1:k))
end program
