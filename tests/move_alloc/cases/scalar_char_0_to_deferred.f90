program p
implicit none
character(0),allocatable :: a
character(:),allocatable :: b
a=''
b='old'
call move_alloc(a,b)
if(allocated(a).or..not.allocated(b)) error stop 1
if(b/=''.or.len(b)/=0) error stop 2
if(len(a)/=0) error stop 3
end program
