module box_mod
implicit none
type :: box_t
 integer :: value
end type
interface operator(+)
 module procedure add_default, add_wide
end interface
contains
function add_default(a,n) result(c)
 type(box_t),intent(in) :: a
 integer,intent(in) :: n
 type(box_t) :: c
 c=box_t(a%value+n)
end function
function add_wide(a,n) result(c)
 type(box_t),intent(in) :: a
 integer(kind=8),intent(in) :: n
 type(box_t) :: c
 c=box_t(a%value+int(n)+100)
end function
end module
program operator_kinds
use box_mod
implicit none
type(box_t) :: a,b
a=box_t(2)+3
b=box_t(2)+3_8
print '(i0)', a%value
print '(i0)', b%value
end program
