module m
implicit none
interface extent_of
module procedure span
end interface
contains
subroutine report(n)
integer,intent(in)::n
integer::work(extent_of(n))
work=1
print *,size(work)
end subroutine
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
end module
program p
use m
implicit none
call report(3)
end program
