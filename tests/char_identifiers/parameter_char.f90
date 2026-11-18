program p
implicit none
integer,parameter::char=3
integer::x(char)
x=char
if(sum(x)/=9) error stop 1
print *,"parameter char"
end program
