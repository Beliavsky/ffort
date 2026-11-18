program p
implicit none
character(:),allocatable::s
s=''
if(.not.allocated(s).or.len(s)/=0.or.s/='') error stop 1
s='grow'
if(len(s)/=4) error stop 2
end program
