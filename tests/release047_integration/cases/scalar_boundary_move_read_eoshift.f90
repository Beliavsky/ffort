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
integer::u,k
integer,allocatable::a(:),b(:)
u=27
allocate(a(-1:2))
read(u,*)a
call move_alloc(a,b)
k=x%a
b=eoshift(b,1,boundary=k)
print '(l1,6i3)',allocated(a),lbound(b),ubound(b),b
end program
