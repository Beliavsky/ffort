! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer function span(n) result(v)
integer,intent(in)::n
integer::i
v=n
do i=1,1000
v=v+1
end do
end function
subroutine work(n)
integer,intent(in)::n
integer::a(0*span(n))
integer,save::calls=0
calls=calls+1
print *,calls,size(a)
end subroutine
end module
program main
use m
implicit none
call work(1)
end program
