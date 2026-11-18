module m
contains
function f() result(x)
real::x
x=1.0
end function
end module
program main
use m
integer,parameter::n=maxexponent(f())
print *,n
end program
