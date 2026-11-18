module factory
implicit none
contains
function text(n) result(s)
integer,intent(in)::n
character(:),allocatable::s
character(6)::tmp
write(tmp,'(i0)') n
s=trim(tmp)
end function
end module
program main
use factory
implicit none
character(:),allocatable::s,t
integer::a,b,ios
s=text(71)
t=text(82)
read(s,*,iostat=ios) a
if(ios/=0) error stop 1
read(t,*,iostat=ios) b
if(ios/=0.or.a/=71.or.b/=82) error stop 2
s=s//', '//t
write(*,'(a)') '['//s//']'
end program
