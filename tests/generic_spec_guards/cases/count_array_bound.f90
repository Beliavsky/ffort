module m
implicit none
interface count
module procedure span
end interface
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine report(n)
integer,intent(in)::n
integer::work(count(n))
work=1
print *,size(work)
end subroutine
end module
program p
use m
implicit none
call report(3)
end program
