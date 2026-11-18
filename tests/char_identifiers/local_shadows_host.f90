module m
implicit none
integer::char
contains
subroutine f()
character(1)::char
char="d"
if(char/="d") error stop 1
print *,char
end subroutine
end module
program p
use m
implicit none
char=18
call f()
if(char/=18) error stop 2
print *,char
end program
