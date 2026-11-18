module m
implicit none
integer,parameter::dp=kind(1d0)
contains
function probe(v) result(y)
real,intent(in)::v(:)
real(dp)::y
y=sum(v)/size(v)
end function
end module
program p
use m
implicit none
real::x(2)=[2.,4.]

print *,probe(x**2_8)
end program
