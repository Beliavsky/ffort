program p
implicit none
integer::u
character(0)::a(2)
integer::b,s
u=27
read(u,*,iostat=s)a,b
if(s/=0)stop 1
print *,b
end program
