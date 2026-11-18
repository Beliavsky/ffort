module optional_bound
implicit none
type :: box
 integer :: value
contains
 procedure :: amount
end type
contains
function amount(this,increment) result(x)
class(box),intent(in) :: this
integer,optional,intent(in) :: increment
integer :: x
x=this%value
if(present(increment)) x=x+increment
end function
end module
program optional_bound_test
use optional_bound
implicit none
type(box) :: b
b=box(4)
print *,b%amount(),b%amount(increment=6)
end program
