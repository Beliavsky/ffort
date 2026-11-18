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
real(8)::a(3)
integer::n,k
k=x%a
n=kind(eoshift(a,k))
print '(2i3)',n,x%a
end program
