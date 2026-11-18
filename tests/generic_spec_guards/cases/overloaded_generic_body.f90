module m
implicit none
interface extent_of
module procedure span,span_real
end interface
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
pure integer function span_real(n) result(v)
real,intent(in)::n
v=7
end function
end module
program p
use m
implicit none
print *,extent_of(3),extent_of(2.0)
end program
