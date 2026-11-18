module m
implicit none
contains
pure integer function read(n)
integer,intent(in)::n
read=n+1
end function
end module
program p
use m
implicit none
if(read(2)/=3) stop 1
print *,1
end
