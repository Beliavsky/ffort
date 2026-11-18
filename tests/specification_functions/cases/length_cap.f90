module m
implicit none
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine run(n)
integer,intent(in)::n
character(len=f(n))::s
s='x'
print *,len(s)
end subroutine
end module
program p
use m
implicit none
call run(65536)
end program
