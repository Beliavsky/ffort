module m
implicit none
character(8)::s
contains
subroutine probe()
if(s%len/=8) error stop 1
end subroutine
end module
program p
use m
implicit none
if(s%len/=8) error stop 1
call probe()
end program
