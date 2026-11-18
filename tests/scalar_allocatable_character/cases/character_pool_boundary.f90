program p
implicit none
character(:),allocatable::s,a(:)
allocate(character(65536)::a(256))
s=''
if(.not.allocated(s).or.len(s)/=0) error stop 1
deallocate(a)
s='x'
if(s/='x') error stop 2
end program
