program p
implicit none
character(:),allocatable::s
call useit(s)
contains
subroutine useit(x)
character(*),allocatable,intent(in)::x
end subroutine
end program
