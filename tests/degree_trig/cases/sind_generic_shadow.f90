module m
interface sind
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
print *,sind(7)
end program
