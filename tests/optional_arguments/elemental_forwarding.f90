module elemental_optional
implicit none
contains
elemental function pick(a,b) result(x)
integer,intent(in) :: a
integer,optional,intent(in) :: b
integer :: x
x=a
if(present(b)) x=b
end function
elemental function bridge(a,b) result(x)
integer,intent(in) :: a
integer,optional,intent(in) :: b
integer :: x
x=pick(a,b)
end function
elemental subroutine reset(a,b)
integer,intent(out) :: a
integer,optional,intent(in) :: b
a=99
if(present(b)) a=b
end subroutine
subroutine bulk(a,b)
integer,intent(out) :: a(:)
integer,optional,intent(in) :: b
call reset(a,b)
end subroutine
end module
program elemental_optional_test
use elemental_optional
implicit none
integer :: a(3),empty(0)
print *,bridge([1,2,3]),bridge([1,2,3],8),bridge([1,2,3],[5,6,7])
call bulk(a)
print *,a
call bulk(a,7)
print *,a
call bulk(empty)
print *,size(empty)
end program
