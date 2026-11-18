! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer(kind=8) function span(n) result(v)
integer(kind=8),intent(in)::n
v=n+1_8
end function
subroutine work(n)
integer(kind=8),intent(in)::n
integer(kind=8)::a(span(n))
integer(kind=8),save::serial=9007199254740992_8
serial=serial+1_8
a=serial
print *,size(a),a
end subroutine
end module
program main
use m
implicit none
call work(1_8)
call work(0_8)
end program
