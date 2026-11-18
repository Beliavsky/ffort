program p
implicit none
integer::u
integer::a(3),b,s
u=27
read(u,*,iostat=s)a
if(s/=0)stop 1
read(u,*,iostat=s)b
if(s/=0)stop 2
print *,a,b
end program
