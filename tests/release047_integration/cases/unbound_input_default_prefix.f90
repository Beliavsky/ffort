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
print '(i0)',x%a
read(u,*)n
end program
