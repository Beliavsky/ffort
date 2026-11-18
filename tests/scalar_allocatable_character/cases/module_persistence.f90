module m
implicit none
character(:),allocatable::s
contains
subroutine change()
if(.not.allocated(s)) then
s='a'
else
s=s//'b'
end if
end subroutine
end module
program p
use m
implicit none
call change()
call change()
if(s/='ab') error stop 1
end program
