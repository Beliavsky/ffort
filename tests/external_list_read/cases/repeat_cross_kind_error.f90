program p
implicit none
integer::u
integer(4)::a
integer(8)::b
integer::s
u=27
read(u,*,iostat=s)a,b
if(s<=0)stop 1
print *,1
end program
