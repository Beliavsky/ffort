program p
implicit none
integer::u
integer::a,s
u=27
read(u,*)a
read(u,*,iostat=s)a
if(s>=0)stop 1
backspace(u,iostat=s)
if(s/=0)stop 2
read(u,*,iostat=s)a
if(s>=0)stop 3
backspace(u)
backspace(u)
read(u,*,iostat=s)a
if(s/=0)stop 4
print *,a
end program
