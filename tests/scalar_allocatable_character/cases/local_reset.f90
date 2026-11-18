program p
implicit none
integer::i
do i=1,3
call work()
end do
contains
subroutine work()
character(:),allocatable::x
if(allocated(x)) error stop 1
x='abc'
end subroutine
end program
