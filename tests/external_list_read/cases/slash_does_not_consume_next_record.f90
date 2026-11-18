program p
implicit none
integer::u
integer::a,b,s
u=27
a=9
read(u,*,iostat=s)a
if(s/=0)stop 1
read(u,*,iostat=s)b
if(s/=0)stop 2
print *,a,b
end program
