program p
implicit none
integer::u
integer::a(2,1,2),s
real(8)::b(1,2,2)
u=27
read(u,*,iostat=s)a,b
if(s/=0)stop 1
print *,a,b
end program
