module m
implicit none
type::box
integer::procedure
end type
end module
program p
use m
implicit none
type(box)::b
b=box(4)
if(b%procedure/=4) error stop 1
print *, 'component name'
end program
