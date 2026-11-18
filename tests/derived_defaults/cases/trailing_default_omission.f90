module types
implicit none
type::dt
integer::a=7
real(8)::b=1.25d0
logical::ok=.true.
end type
end module
program p
use types
implicit none
type(dt)::x
x=dt(9)
print '(i3,f6.2,l2)',x%a,x%b,x%ok
end program
