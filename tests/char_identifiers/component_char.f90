module m
implicit none
type::t
integer::char
end type
end module
program p
use m
implicit none
type(t)::v
v%char=19
if(v%char/=19) error stop 1
print *,v%char,char(100)
end program
