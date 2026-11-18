module m
implicit none
contains
integer function f(i) result(char)
integer,intent(in)::i
char=i+5
end function
end module
program p
use m
implicit none
if(f(3)/=8) error stop 1
print *,f(2),char(100)
end program
