program p
implicit none
integer::u
integer::a(2),b(2),s
u=27
read(u,*,iostat=s)a,b
if(s/=0)stop 1
print *,a,b
end program
