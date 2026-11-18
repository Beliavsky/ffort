module m
implicit none
contains
function f(back) result(v)
logical,optional,intent(in)::back
integer::v(1)
v=minloc([1,2],back=back)
end function
end module
program test
use m
implicit none
print *,f()
end program
