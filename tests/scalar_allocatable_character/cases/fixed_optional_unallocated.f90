program p
implicit none
character(4),allocatable::s
call probe()
call probe(s)
contains
subroutine probe(x)
character(*),allocatable,optional,intent(in)::x
if(present(x)) then
if(allocated(x).or.len(x)/=4) error stop 1
end if
end subroutine
end program
