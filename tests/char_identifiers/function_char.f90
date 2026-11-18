module m
implicit none
contains
integer function char(i) result(outcome)
integer,intent(in)::i
outcome=i+3
end function
end module
program p
use m
implicit none
if(char(i=4)/=7) error stop 1
print *,char(5)
end program
