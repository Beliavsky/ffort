program p
implicit none
character(65536),allocatable :: a(:),b(:)
allocate(a(128),b(1))
call move_alloc(a,b)
if(allocated(a).or.size(b)/=128.or.len(b)/=65536)error stop 1
end program
