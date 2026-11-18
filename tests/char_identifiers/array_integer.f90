program p
implicit none
integer::char(3)
char=[4,5,6]
char(2)=9
if(any(char/=[4,9,6])) error stop 1
print *,char(2),sum(char)
end program
