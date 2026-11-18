program p
implicit none
character(:),allocatable :: a,b
a='first';b='old allocation'
call outer(a,b)
if(allocated(a).or.b/='first'.or.len(b)/=5) error stop 1
a='replacement'
if(b/='first') error stop 2
contains
subroutine outer(x,y)
character(:),allocatable,intent(inout) :: x,y
call inner(x,y)
end subroutine
subroutine inner(x,y)
character(:),allocatable,intent(inout) :: x,y
call move_alloc(from=x,to=y)
end subroutine
end program
