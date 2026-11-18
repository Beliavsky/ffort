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
integer::work(span(n))
character(len=span(n))::word
work=1
word="x"
print *,size(work),len(word)
end subroutine
end module
program p
use m
implicit none
call report(3)
end program
