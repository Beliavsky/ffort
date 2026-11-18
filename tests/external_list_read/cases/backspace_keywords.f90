program p
implicit none
integer::u
integer::a,b,s
u=27
read(u,*)a
backspace(unit=u,iostat=s)
read(u,*,iostat=s)b
if(s/=0)stop 1
print *,a,b
end program
