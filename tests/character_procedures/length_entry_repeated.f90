module m
implicit none
contains
subroutine f(n,buffer)
integer,intent(in)::n
character(*),intent(out)::buffer
character(n)::x
x="abcdef"
buffer=x
end subroutine
end module
program test
use m
implicit none
character(6)::buffer
call f(2,buffer)
print *,buffer//"|"
call f(4,buffer)
print *,buffer//"|"
end program
