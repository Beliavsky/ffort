program p
implicit none
integer::u
character(3)::a,b
integer::s
u=27
read(u,*,iostat=s)a,b
if(s/=0)stop 1
print "(a)",a,b
end program
