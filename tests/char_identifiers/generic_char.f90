module m
implicit none
interface char
module procedure convert
end interface
contains
character(1) function convert(i) result(value)
integer,intent(in)::i
value="Z"
end function
end module
program p
use m
implicit none
if(char(65)/="Z") error stop 1
print *,char(65)
end program
