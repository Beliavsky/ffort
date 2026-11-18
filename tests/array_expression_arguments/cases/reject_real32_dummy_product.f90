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
real(dp)::x(4)=[1d0,2d0,3d0,4d0]

print *,probe(x*x)
end program
