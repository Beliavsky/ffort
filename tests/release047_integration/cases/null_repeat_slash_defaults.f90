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
integer::u,a(4)
u=27
a=[1,2,3,4]
read(u,*)a
print '(5i3)',a,x%a
end program
