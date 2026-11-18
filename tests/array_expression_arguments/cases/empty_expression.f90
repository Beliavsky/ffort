module m
implicit none
integer,parameter::dp=kind(1d0)
contains
function probe(v) result(y)
real(dp),intent(in)::v(:)
real(dp)::y
y=sum(v)
end function
end module
program p
use m
implicit none
real(dp)::x(0)

print *,probe(x**2)
end program
