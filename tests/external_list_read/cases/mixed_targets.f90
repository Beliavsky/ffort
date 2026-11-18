program p
implicit none
integer::u
integer::a,s
real(8)::b
character(4)::c(2)
u=27
read(u,*,iostat=s)a,b,c
if(s/=0.or.a/=42.or.b/=1.5d0)stop 1
print "(a)",c
end program
