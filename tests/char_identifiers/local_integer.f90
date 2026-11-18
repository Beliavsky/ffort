program p
implicit none
integer::char
char=7
if(char/=7) error stop 1
print *,"local integer"
end program
