module m
implicit none
interface char
module procedure span
end interface
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine report(n)
integer,intent(in)::n
character(len=char(n))::word
word="x"
print *,len(word)
end subroutine
end module
program p
use m
implicit none
call report(3)
end program
