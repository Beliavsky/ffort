program p
implicit none
integer::u
integer(4)::a(3)
integer(8)::b(3)
integer::s
u=27
read(u,*,iostat=s)a,b
if(s/=0)stop 1
print *,a,b
end program
