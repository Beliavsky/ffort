! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer function span(n) result(v)
integer,intent(in)::n
integer,save::calls=0
v=n+calls
end function
subroutine work(n)
integer,intent(in)::n
integer::a(0*span(n))
print *,size(a)
end subroutine
end module
program main
use m
implicit none
call work(0)
end program
