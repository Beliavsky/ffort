program p
implicit none
character(:),allocatable::s
allocate(character(5)::s)
if(.not.allocated(s).or.len(s)/=5) error stop 1
s(:)='abc'
if(s/='abc  ') error stop 2
deallocate(s)
if(allocated(s)) error stop 3
s='x'
if(s/='x'.or.len(s)/=1) error stop 4
end program
