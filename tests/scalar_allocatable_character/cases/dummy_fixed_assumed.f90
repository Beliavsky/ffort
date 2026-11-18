program p
implicit none
character(4),allocatable::s
s='a'
call grow(s)
if(s/='xy  '.or.len(s)/=4) error stop 1
contains
subroutine grow(x)
character(*),allocatable,intent(inout)::x
if(len(x)/=4) error stop 2
x='xy'
end subroutine
end program
