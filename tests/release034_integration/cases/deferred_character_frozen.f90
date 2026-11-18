module m
implicit none
contains
subroutine report(char)
character(:),allocatable,intent(inout)::char(:,:)
character(len=size(char))::label
logical::mask(size(char,1),size(char,2))
integer,save::calls=0
calls=calls+1
label=' x '
mask=.true.
deallocate(char)
allocate(character(2)::char(1,1))
char='yz'
write(*,'("[",a,"]",4(1x,i0))')label,len(label),size(mask),len(char),calls
write(*,'("mask:",2(1x,l1))')mask
end subroutine
end module
program main
use m
implicit none
character(:),allocatable::data(:,:)
allocate(character(7)::data(2,2))
call report(data)
call report(data)
end program
