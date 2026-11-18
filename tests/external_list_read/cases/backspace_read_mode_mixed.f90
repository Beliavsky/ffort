program p
implicit none
integer::u
integer::a,s
character(6)::line
u=27
read(u,*)a
backspace(u)
read(u,"(a)",iostat=s)line
if(s/=0)stop 1
print "(a)",line
end program
