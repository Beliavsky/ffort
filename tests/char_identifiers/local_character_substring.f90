program p
implicit none
character(4)::char
char="abcd"
char(2:3)="XY"
if(char(1:4)/="aXYd") error stop 1
print *,char
end program
