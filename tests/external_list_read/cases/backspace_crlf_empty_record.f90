program p
implicit none
integer::u
integer::a,s
character(4)::line
u=27
read(u,*)a
read(u,"(a)")line
if(line/=" ")stop 1
backspace(u)
read(u,"(a)")line
if(line/=" ")stop 2
read(u,*)a
print *,a
end program
