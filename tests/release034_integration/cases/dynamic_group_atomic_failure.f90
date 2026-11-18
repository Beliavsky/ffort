module m
implicit none
contains
subroutine report(char)
integer,allocatable,intent(in)::char(:)
integer::work(size(char))
work=7
write(*,'(a)')'before grouped write'
write(*,'(a,2(i0),a)')'must not leak',work,'done'
end subroutine
end module
program main
use m
integer,allocatable::data(:)
allocate(data(3))
call report(data)
end program
