module m
implicit none
integer,parameter::dp=kind(1d0)
contains
function probe(v) result(y)
real(dp),intent(in)::v
real(dp)::y
y=v
end function
end module
program p
use m
implicit none
real(dp)::x(4)=3d0

print *,probe(x(2)**2)
end program
