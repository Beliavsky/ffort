program main
implicit none
character(5)::s(2)
s="ababa"
call f(s)
contains
subroutine f(s,b)
character(*),intent(in)::s(:)
logical,optional,intent(in)::b(:)
print *, index(s,'ba',.not.b)
end subroutine
end program
