program p
implicit none
integer::u
integer::a(5),s
u=27
a=[1,2,3,4,5]
read(u,*,iostat=s)a
if(s/=0)stop 1
print *,a
end program
