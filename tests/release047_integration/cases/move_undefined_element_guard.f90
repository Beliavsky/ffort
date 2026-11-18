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
integer,allocatable::a(:),b(:)
allocate(a(1))
call move_alloc(a,b)
print '(i0)',x%a
print '(i0)',b(1)
end program
