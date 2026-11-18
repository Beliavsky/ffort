program p
implicit none
character(1)::char(3)
char=["a","d","e"]
if(char(2)/="d") error stop 1
print *,char(1),char(2),char(3)
end program
