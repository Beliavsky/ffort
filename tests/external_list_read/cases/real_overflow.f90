program p
implicit none
integer::u
real(8)::a
integer::s
u=27
read(u,*,iostat=s)a
if(s<=0)stop 1
print *,1
end program
