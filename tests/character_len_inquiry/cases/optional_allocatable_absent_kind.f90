program p
implicit none
integer::n
call probe()
contains
subroutine probe(x)
character(:),allocatable,optional,intent(in)::x
if(kind(x%len)/=4) error stop 1
end subroutine
end program
