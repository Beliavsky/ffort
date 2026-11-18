module m
implicit none
interface extent_of
module procedure span
end interface
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine report(n)
integer,intent(in)::n
integer::v
v=extent_of(n=n)
print *,v
end subroutine
end module
program p
use m
implicit none
call report(3)
end program
