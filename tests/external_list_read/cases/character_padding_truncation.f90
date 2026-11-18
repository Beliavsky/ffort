program p
implicit none
integer::u
character(4)::a,b,c
integer::s
u=27
read(u,*,iostat=s)a,b,c
if(s/=0)stop 1
print "(a)","["//a//"]","["//b//"]","["//c//"]"
end program
