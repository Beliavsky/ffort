program p
implicit none
character(:),allocatable::s
s='abc'
call remove(s)
if(allocated(s)) error stop 1
contains
subroutine remove(x)
character(:),allocatable,intent(inout)::x
deallocate(x)
end subroutine
end program
