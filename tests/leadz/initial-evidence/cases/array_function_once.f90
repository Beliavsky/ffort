module m
integer::calls=0
contains
function f() result(a)
integer(8)::a(3)
calls=calls+1
a=[0_8,1_8,-1_8]
end function
end module
program p
use m
implicit none
print *,leadz(f())
print *,calls
end program
