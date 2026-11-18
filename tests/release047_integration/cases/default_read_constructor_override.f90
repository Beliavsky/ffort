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
integer::u,n
u=27
print '(i3,f5.1)',x%a,x%y
read(u,*)n
x=dt(n)
print '(i3,f5.1)',x%a,x%y
end program
