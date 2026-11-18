module m
implicit none
type::box
integer::x
contains
procedure::procedure=>get
end type
contains
integer function get(this) result(y)
class(box),intent(in)::this
y=this%x
end function
end module
program p
use m
implicit none
type(box)::b
b=box(4)
if(b%procedure()/=4) error stop 1
print *, 'type bound name'
end program
