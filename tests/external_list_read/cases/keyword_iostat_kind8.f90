program p
implicit none
integer::u
integer(8)::v,s
integer::a
u=27
v=27
read(unit=v,fmt=*,iostat=s)a
if(s/=0)stop 1
print *,a
end program
