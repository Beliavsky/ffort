module types
implicit none
type::dt
integer::a=7
real(8)::b=2.0d0
end type
end module
program p
use types
implicit none
type(dt)::x
x=dt(4.75,9)
print '(i3,f5.1)',x%a,x%b
end program
