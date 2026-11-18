program p
implicit none
character(7)::s
call probe(s)
contains
subroutine probe(x)
character(*),intent(out)::x
if(x%len/=7) error stop 1
end subroutine
end program
