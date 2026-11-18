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
type(dt)::x,y
integer::u,n
u=27
read(u,*)n
x=dt(n)
backspace u
read(u,*)n
y=dt(n+1)
print '(2i3,f5.1)',x%a,y%a,x%y
end program
