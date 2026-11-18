module types
implicit none
integer(8),parameter::n=-11_8
type::dt
integer(8)::a=abs(n)+3_8
real(8)::b=real(n,8)/2.0d0
end type
end module
program p
use types
implicit none
type(dt)::x
print '(i4,f8.1)',x%a,x%b
end program
