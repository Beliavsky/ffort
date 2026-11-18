module types
implicit none
type::dt
integer::a=3.75d0
real(8)::b=7_8
logical::ok=.not..false.
end type
end module
program p
use types
implicit none
type(dt)::x
print '(i3,f6.2,l2)',x%a,x%b,x%ok
end program
