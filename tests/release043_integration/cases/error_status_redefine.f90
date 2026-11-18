program main
implicit none
character(:),allocatable::s
integer::v(2),ios
s='4,bad'
read(s,*,iostat=ios) v
if(ios<=0) error stop 1
v=[8,9]
s='1'
read(s,*,iostat=ios) v
if(ios>=0) error stop 2
v=[10,11]
s='2*6'
read(s,*,iostat=ios) v
if(ios/=0.or.any(v/=6)) error stop 3
write(*,'(a)') 'ok'
end program
