module m
contains
subroutine set(s)
character(*),intent(in)::s
s(1:2)='a'
end subroutine
end module
program test
end program
