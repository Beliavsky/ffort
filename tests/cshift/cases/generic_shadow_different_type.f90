module m
implicit none
interface cshift
module procedure positive
end interface
contains
logical function positive(n) result(r)
integer,intent(in)::n
r=n>0
end function
end module
program p
use m
implicit none
if(.not.cshift(4)) error stop 1
if(cshift(-1)) error stop 2
print *, "PASS"
end program
