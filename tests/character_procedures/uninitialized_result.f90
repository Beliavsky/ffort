module m
implicit none
contains
function make() result(x)
character(3)::x(2)
x(1)="a"
end function
end module m
program test
use m
implicit none
character(3)::a(2)
a=make()
end program test
