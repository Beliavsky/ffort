program p
implicit none
integer::u
integer(8)::v,s
integer::a
u=27
v=27
read(v,*)a
backspace(unit=v,iostat=s)
if(s/=0)stop 1
read(v,*)a
print *,a
end program
