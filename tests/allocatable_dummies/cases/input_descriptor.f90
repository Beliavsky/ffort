module m

contains
pure function inspect(a) result(n)
integer,allocatable,intent(in)::a(:)
integer::n
n=-8
if(allocated(a)) n=lbound(a,1)+ubound(a,1)+sum(a)
end function
end module
program main
use m
integer,allocatable::v(:)
print *,inspect(v)
allocate(v(-1:1))
v=[2,4,6]
print *,inspect(v)
end program
