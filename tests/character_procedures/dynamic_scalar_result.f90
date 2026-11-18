module m
implicit none
contains
function pad(x,n) result(y)
character(*),intent(in)::x
integer,intent(in)::n
character(n)::y
y=x
end function
end module m
program test
use m
implicit none
character(6) :: a
a=pad("xy",5)
print *,a//"|"
end program test
