program p
implicit none
integer::u
integer::a,s
u=27
read(u,*,iostat=s)a
if(s>=0)stop 1
backspace(u)
backspace(u,iostat=s)
if(s/=0)stop 2
read(u,*,iostat=s)a
if(s>=0)stop 3
print *,1
end program
