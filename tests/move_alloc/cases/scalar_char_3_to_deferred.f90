program p
implicit none
character(3),allocatable :: a
character(:),allocatable :: b
a='abc'
b='old'
call move_alloc(a,b)
if(allocated(a).or..not.allocated(b)) error stop 1
if(b/='abc'.or.len(b)/=3) error stop 2
if(len(a)/=3) error stop 3
end program
