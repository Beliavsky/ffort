module m
implicit none
contains
subroutine tick()
integer,save::i=0
print *,i
do i=1,2
end do
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
