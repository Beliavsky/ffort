program p
implicit none
integer::u
integer::a,s
character(8)::line
u=27
read(u,*,iostat=s)a
if(s<=0)stop 1
backspace(u)
read(u,"(a)",iostat=s)line
if(s/=0)stop 2
print "(a)",line
end program
