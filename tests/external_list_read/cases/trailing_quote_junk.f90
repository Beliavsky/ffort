program p
implicit none
integer::u
character(3)::a
integer::s
u=27
read(u,*,iostat=s)a
if(s<=0)stop 1
print *,1
end program
