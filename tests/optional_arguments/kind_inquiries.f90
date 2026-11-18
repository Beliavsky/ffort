module optional_inquiries
implicit none
contains
function ignored(a,b) result(x)
integer,intent(in) :: a
real(8),optional,intent(in) :: b
real(8) :: x
x=a
end function
subroutine check(x)
integer,optional,intent(in) :: x
integer,parameter :: present_kind=kind(present(x))
print *,kind(x),kind(present(x)),present_kind
print *,kind(ignored(a=1)),kind(ignored(1,2.0_8))
end subroutine
end module
program kind_inquiry_test
use optional_inquiries
implicit none
integer :: undefined
call check()
call check(undefined)
end program
