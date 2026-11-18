module m
interface index
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
print *,index(3),index(a=5)
end program
