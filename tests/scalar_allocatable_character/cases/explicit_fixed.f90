program p
implicit none
character(3),allocatable::s
allocate(s)
if(len(s)/=3) error stop 1
s='a'
if(s/='a  ') error stop 2
deallocate(s)
if(allocated(s).or.len(s)/=3) error stop 3
end program
