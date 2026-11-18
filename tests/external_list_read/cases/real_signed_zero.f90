program p
implicit none
integer::u
real(4)::a
real(8)::b
integer::s
u=27
read(u,*,iostat=s)a,b
if(s/=0)stop 1
print *,a,b
end program
