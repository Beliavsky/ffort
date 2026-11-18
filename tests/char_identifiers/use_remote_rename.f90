module m
implicit none
integer::char
end module
program p
use m,only:value=>char
implicit none
value=12
if(value/=12) error stop 1
print *,value,char(101)
end program
