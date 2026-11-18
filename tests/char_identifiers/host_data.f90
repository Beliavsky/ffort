module m
implicit none
integer::char(2)
contains
subroutine f()
char=[13,14]
if(char(2)/=14) error stop 1
print *,char
end subroutine
end module
program p
use m,only:f
implicit none
call f()
print *,char(65)
end program
