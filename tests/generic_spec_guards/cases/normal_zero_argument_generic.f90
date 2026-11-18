module m
implicit none
interface extent_of
module procedure span
end interface
contains
pure integer function span() result(v)
v=4
end function
subroutine report(n)
integer,intent(in)::n
integer::v
v=extent_of()
print *,v
end subroutine
end module
program p
use m
implicit none
call report(3)
end program
