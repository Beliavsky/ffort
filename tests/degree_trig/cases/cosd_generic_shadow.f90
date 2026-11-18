module m
interface cosd
module procedure f
end interface
contains
integer function f(i)
integer,intent(in)::i
f=i+1
end function
end module
program p
use m
print *,cosd(7)
end program
