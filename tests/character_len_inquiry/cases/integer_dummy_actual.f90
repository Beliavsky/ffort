program p
implicit none
character(7)::s(0)
call probe(s%len)
contains
subroutine probe(n)
integer,intent(in)::n
if(n/=7) error stop 1
end subroutine
end program
