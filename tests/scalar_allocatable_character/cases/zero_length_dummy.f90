program p
implicit none
character(:),allocatable::s
s=''
call change(s)
if(.not.allocated(s).or.len(s)/=0.or.s/='') error stop 1
contains
subroutine change(x)
character(:),allocatable,intent(inout)::x
if(.not.allocated(x).or.len(x)/=0) error stop 2
x=''
end subroutine
end program
