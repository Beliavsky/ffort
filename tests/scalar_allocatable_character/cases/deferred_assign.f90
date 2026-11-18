program p
implicit none
character(:),allocatable::s
if(allocated(s)) error stop 1
s='abc'
if(.not.allocated(s).or.len(s)/=3.or.s/='abc') error stop 2
s='z'
if(len(s)/=1.or.s/='z') error stop 3
end program
