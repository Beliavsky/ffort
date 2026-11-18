module m
implicit none
integer::char(2)
end module
program p
use m,only:char
implicit none
char=[8,9]
if(char(2)/=9) error stop 1
print *,char
end program
