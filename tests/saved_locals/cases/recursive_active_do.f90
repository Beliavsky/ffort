module m
implicit none
contains
recursive subroutine tick(depth)
integer,intent(in)::depth
integer,save::i=0
do i=1,2
if(depth>0) call tick(depth-1)
end do
end subroutine
end module
program p
use m
implicit none
call tick(1)
end program
