program p
implicit none
character(3),parameter::char="AdE"
if(char(2:2)/="d") error stop 1
print *,char
end program
