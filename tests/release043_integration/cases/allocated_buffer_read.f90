program main
implicit none
character(:),allocatable::s
integer::a(3),ios,n
s='2*7,9'
read(s,*,iostat=ios) a
if(ios/=0.or.any(a/=[7,7,9])) error stop 1
if(.not.allocated(s).or.len(s)/=5.or.s/='2*7,9') error stop 2
s=s(3:)
read(s,*,iostat=ios) n
if(ios/=0.or.n/=7.or.len(s)/=3) error stop 3
write(*,'(a)') 'ok'
end program
