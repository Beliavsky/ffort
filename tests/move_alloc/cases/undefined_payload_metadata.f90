program p
implicit none
integer,allocatable :: a(:),b(:)
allocate(a(3))
a(2)=7
call move_alloc(a,b)
if(allocated(a).or.size(b)/=3.or.b(2)/=7) error stop 1
b(1)=5;b(3)=9
if(any(b/=[5,7,9])) error stop 2
end program
