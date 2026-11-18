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
allocate(b(2))
b=x%a
call move_alloc(a,b)
print '(2l1,i3)',allocated(a),allocated(b),x%a
end program
