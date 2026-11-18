module m
interface total
module procedure sum_int
end interface
contains
pure recursive integer function sum_int(n) result(v)
integer,intent(in)::n
if(n==0) then
v=0
else
v=n+total(n-1)
end if
end function
end module
program p
use m
print *,total(5)
end program
