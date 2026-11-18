program main
implicit none
call fail()
contains
subroutine fail(x)
character(:),allocatable,optional,intent(in)::x
end subroutine
end program
