module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
end module
program p
use types
implicit none
type(dt)::x
integer::u,n,s
u=27
n=99
read(u,*,iostat=s)n
print '(l1,i3,f5.1)',s>0,x%a,x%y
end program
