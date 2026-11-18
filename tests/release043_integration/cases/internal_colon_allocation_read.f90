program main
implicit none
character(:),allocatable::s
integer::n,ios
allocate(character(12)::s)
write(s,'(i0,:,",",i0)') digits(1)
if(s/='31          ') error stop 1
read(s,*,iostat=ios) n
if(ios/=0.or.n/=31.or.len(s)/=12) error stop 2
write(*,'(a)') '['//s//']'
end program
