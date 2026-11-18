module m
implicit none
contains
subroutine take(char)
character(*),intent(in)::char
if(char/="Abd") error stop 1
if(char(2:3)/="bd") error stop 2
print *,char
end subroutine
subroutine convert()
if(char(i=65,kind=1)/="A") error stop 3
print *,char(100)
end subroutine
end module
program p
use m
implicit none
call take(char="Abd")
call convert()
end program
