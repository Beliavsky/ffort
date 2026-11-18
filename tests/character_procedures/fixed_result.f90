module m
implicit none
contains
function make() result(x)
character(3)::x(2)
x=["a","b"]
end function
end module m
program test
use m
implicit none
character(3) :: a(2)
a=make()
print *,a(1)//"|",a(2)//"|"
end program test
