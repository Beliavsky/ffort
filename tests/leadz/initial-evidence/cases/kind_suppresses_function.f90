module m
integer::calls=0
contains
function f() result(a)
integer(8)::a
calls=calls+1
a=1_8
end function
end module
program p
use m
implicit none
print *,kind(leadz(f()))
print *,calls
end program
