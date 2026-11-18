module statistics_mod
implicit none
type :: dt
integer :: a=7,b=8
end type dt
contains
subroutine copy_test(v)
type(dt),intent(in)::v
type(dt)::w
w=v
w%a=10
print '(2(i0,1x))',w%a,w%b
end subroutine
end module

use statistics_mod
implicit none
type(dt) :: x
call copy_test(x)
print '(2(i0,1x))',x%a,x%b
end
