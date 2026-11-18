! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine work(n)
integer,intent(in)::n
integer::a(span(n))
integer,save::calls=span(1)
a=calls
print *,sum(a)
end subroutine
end module
program main
use m
implicit none
call work(1)
end program
