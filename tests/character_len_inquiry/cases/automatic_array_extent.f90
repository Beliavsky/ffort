program p
implicit none
character(7)::s
call probe(s)
contains
subroutine probe(x)
character(*),intent(in)::x
integer::a(x%len)
if(size(a)/=7) error stop 1
end subroutine
end program
