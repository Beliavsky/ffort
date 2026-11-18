program p
implicit none
character(:),allocatable::s
allocate(character(0)::s)
if(.not.allocated(s).or.len(s)/=0) error stop 1
s(:)=''
if(s/='') error stop 2
deallocate(s)
allocate(character(-5)::s)
if(.not.allocated(s).or.len(s)/=0) error stop 3
end program
