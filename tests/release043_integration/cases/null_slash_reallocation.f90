program main
implicit none
character(:),allocatable::s
integer::v(3),ios
v=[10,20,30]
s=',7,/'
read(s,*,iostat=ios) v
if(ios/=0.or.any(v/=[10,7,30])) error stop 1
s='3*2'
read(s,*,iostat=ios) v
if(ios/=0.or.any(v/=2)) error stop 2
write(*,'(a)') 'ok'
end program
