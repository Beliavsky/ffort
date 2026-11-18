program p
implicit none
character(7)::s
call probe(s)
contains
subroutine probe(x)
character(*),optional,intent(in)::x
if(.not.present(x)) error stop 1
if(x%len/=7) error stop 2
end subroutine
end program
