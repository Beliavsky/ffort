module m
implicit none
contains
integer function char(i)
integer,intent(in)::i
char=i+1
end function
end module
program p
use m
implicit none
if(char(65)/=66) error stop 1
print *,char(65)
end program
