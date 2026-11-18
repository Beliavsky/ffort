program p
implicit none
character(:),allocatable::s
allocate(character(3)::s)
call fill(s)
if(s/='xyz') error stop 1
contains
subroutine fill(x)
character(:),allocatable,intent(inout)::x
if(.not.allocated(x).or.len(x)/=3) error stop 2
x(:)='xyz'
end subroutine
end program
