program p
implicit none
character(:),allocatable::s
call useit()
contains
subroutine useit(x)
character(:),allocatable,optional,intent(in)::x
print *,allocated(x)
end subroutine
end program
