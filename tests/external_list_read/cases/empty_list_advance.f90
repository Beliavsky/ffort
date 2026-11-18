program p
implicit none
integer::u
integer::b,s
u=27
read(u,*,iostat=s)
if(s/=0)stop 1
read(u,*,iostat=s)b
if(s/=0)stop 2
print *,b
end program
