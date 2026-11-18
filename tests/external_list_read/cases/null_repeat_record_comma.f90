program p
implicit none
integer::u
integer::a(5),s
u=27
a=9
read(u,*,iostat=s)a
if(s/=0)stop 1
print *,a
end program
