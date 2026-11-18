module m
implicit none
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine run(n)
integer,intent(in)::n
character(len=f(f(n=n)))::s
s='abcdef'
print *,len(s),s
end subroutine
end module
program p
use m
implicit none
call run(3)
end program
