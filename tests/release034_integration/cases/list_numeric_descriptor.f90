module m
implicit none
contains
subroutine report(char)
real(8),allocatable,intent(in)::char(:)
real(8)::work(size(char))
integer(8)::exact
work=char*0.5d0
exact=9007199254740993_8
write(*,*)exact,work
end subroutine
end module
program main
use m
real(8),allocatable::data(:)
allocate(data(3))
data=[-1.5d0,0.0d0,2.25d0]
call report(data)
end program
