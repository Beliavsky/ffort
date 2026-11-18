program p
implicit none
integer::u
integer::a(2),s
u=27
read(u,*,iostat=s)a
if(s/=0)stop 1
print *,a
end program
