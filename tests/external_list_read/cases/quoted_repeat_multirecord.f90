program p
implicit none
integer::u
character(4)::a(2)
integer::b,s
u=27
read(u,*,iostat=s)a,b
if(s/=0.or.b/=3)stop 1
print "(a)",a
end program
