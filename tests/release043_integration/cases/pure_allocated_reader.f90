module readers
implicit none
contains
pure subroutine parse(s,n,ios)
character(:),allocatable,intent(in)::s
integer,intent(out)::n,ios
read(s,*,iostat=ios) n
end subroutine
end module
program main
use readers
implicit none
character(:),allocatable::s
integer::n,ios
s='123'
call parse(s,n,ios)
if(ios/=0.or.n/=123) error stop 1
write(*,'(a)') 'ok'
end program
