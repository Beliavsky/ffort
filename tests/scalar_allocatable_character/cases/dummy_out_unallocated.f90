program p
implicit none
character(:),allocatable::s
s='old'
call erase(s)
if(allocated(s)) error stop 1
contains
subroutine erase(x)
character(:),allocatable,intent(out)::x
if(allocated(x)) error stop 2
end subroutine
end program
