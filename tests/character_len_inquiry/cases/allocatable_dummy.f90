program p
implicit none
character(:),allocatable::s
s='abc'
call probe(s)
contains
subroutine probe(x)
character(:),allocatable,intent(in)::x
if(x%len/=3) error stop 1
end subroutine
end program
