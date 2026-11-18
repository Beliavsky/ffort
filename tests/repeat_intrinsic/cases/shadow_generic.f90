module m
interface repeat
module procedure local_repeat
end interface
contains
integer function local_repeat(x)
integer,intent(in)::x
local_repeat=x+30
end function
end module
program p
use m
implicit none
print *,repeat(4)
end program
