module m
implicit none
contains
subroutine report(char)
logical,allocatable,intent(in)::char(:,:,:)
integer::work(lbound(char,1):ubound(char,1),size(char,2),size(char,3))
character(len=size(char,3))::label
work=9
label='Q '
write(*,'("[",a,"]",4(1x,i0))')label,shape(work),size(char)
write(*,'("data:",2("[",2(i2),"]"))')work
end subroutine
end module
program main
use m
implicit none
logical,allocatable::data(:,:,:)
allocate(data(-1:0,2,2))
data=.true.
call report(data)
deallocate(data)
allocate(data(0,2,2))
call report(data)
write(*,'("intrinsic:",2("[",a,"]"))')char([65,32])
end program
