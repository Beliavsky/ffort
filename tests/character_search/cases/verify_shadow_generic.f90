module m
interface verify
module procedure position_int
end interface
contains
integer function position_int(a) result(v)
integer,intent(in)::a
v=a+2
end function
end module
program p
use m
print *,verify(3),verify(a=5)
end program
