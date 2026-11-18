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
read(u,*)n
read(u,*,iostat=s)n
print '(l1,i3)',s<0,x%a
backspace u
backspace u
read(u,*)n
print '(i3)',n
end program
