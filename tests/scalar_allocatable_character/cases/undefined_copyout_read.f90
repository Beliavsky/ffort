program p
implicit none
character(:),allocatable::s
allocate(character(3)::s)
call noop(s)
print *,s
contains
subroutine noop(x)
character(:),allocatable,intent(inout)::x
if(len(x)/=3) error stop 1
end subroutine
end program
