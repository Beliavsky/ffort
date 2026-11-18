program p
implicit none
integer::u
integer::a,s
u=27
read(u,*)a
backspace(u)
backspace(u,iostat=s)
if(s/=0)stop 1
read(u,*)a
print *,a
end program
