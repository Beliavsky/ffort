program p
implicit none
integer::u
integer::a,s
real(8)::b
character(3)::c
u=27
a=7
b=1.5d0
c="old"
read(u,*,iostat=s)a,b,c
if(s/=0.or.a/=7.or.b/=1.5d0)stop 1
print "(a)",c
end program
