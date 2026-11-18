program p
implicit none
character(4),allocatable::s
call grow(s)
if(s/='xy  '.or.len(s)/=4) error stop 1
contains
subroutine grow(x)
character(4),allocatable,intent(out)::x
if(allocated(x).or.len(x)/=4) error stop 2
x='xy'
end subroutine
end program
