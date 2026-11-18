program p
implicit none
character(:),allocatable::s
call probe(s)
contains
subroutine probe(x)
character(:),allocatable,intent(in)::x
if(allocated(x)) error stop 1
if(kind(x)/=kind('a')) error stop 2
end subroutine
end program
