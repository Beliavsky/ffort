program p
implicit none
character(:),allocatable :: a,b
allocate(character(3)::a)
call move_alloc(a,b)
if(allocated(a).or.len(b)/=3) error stop 1
b='new'
if(b/='new') error stop 2
end program
