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
character(len=extent_of(n))::word
word="x"
print *,len(word)
end subroutine
end module
program p
use m
implicit none
call report(3)
end program
