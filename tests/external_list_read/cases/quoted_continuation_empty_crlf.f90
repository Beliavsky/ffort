program p
implicit none
integer::u
character(8)::a
integer::s
u=27
read(u,*,iostat=s)a
if(s/=0)stop 1
print "(a)",a
end program
