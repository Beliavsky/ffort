module m
implicit none
contains
subroutine report(char)
integer,allocatable,intent(in)::char(:)
integer::work(size(char))
write(*,'(a)')'must not appear'
end subroutine
end module
program main
use m
integer,allocatable::data(:)
allocate(data(500001))
write(*,'(a)')'before entry'
call report(data)
end program
