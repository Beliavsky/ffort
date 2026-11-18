module m
implicit none
contains
subroutine report(char)
integer,allocatable,intent(in)::char(:)
integer::work(size(char))
integer,save::calls=0
calls=calls+1
work=calls
write(*,'("body:",2(1x,i0))')calls,work
end subroutine
end module
program main
use m
integer,allocatable::data(:)
write(*,'(a)')'before entry'
call report(data)
end program
