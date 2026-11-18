program p
implicit none
character(7)::s(0)
call probe(s)
contains
subroutine probe(x)
character(*),intent(in)::x(:)
if(x%len/=7) error stop 1
end subroutine
end program
