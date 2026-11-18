module m
implicit none
integer::values(2)
end module
program p
use m,only:char=>values
implicit none
char=[10,11]
if(char(1)/=10) error stop 1
print *,char
end program
