program p
implicit none
character(4),allocatable::s
call useit(s)
contains
subroutine useit(x)
character(3),allocatable,intent(in)::x
if(allocated(x)) error stop 1
end subroutine
end program
