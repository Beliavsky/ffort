program p
implicit none
integer::u
integer::a,s
character(3)::b
u=27
read(u,*,iostat=s)a,b
if(s<=0)stop 1
print *,1
end program
