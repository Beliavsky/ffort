module optional_kinds
implicit none
contains
elemental function wide(a,b) result(x)
integer(8),intent(in) :: a
integer(8),optional,intent(in) :: b
integer(8) :: x
x=a
if(present(b)) x=b
end function
elemental subroutine set_value(a,b,c)
integer,intent(out) :: a
integer,optional,intent(out) :: b
integer,optional,intent(in) :: c
a=1
if(present(b)) b=2
if(present(c)) a=c
end subroutine
end module
program optional_kind_test
use optional_kinds
implicit none
integer :: a(3),b(3),empty(0),undefined
print *,wide(9223372036854775807_8),wide(1_8,9223372036854775807_8)
print *,wide([1_8,2_8,3_8])
call set_value(a)
print *,a
call set_value(a,b,c=7)
print *,a,b
call set_value(empty,c=undefined)
print *,size(empty)
end program
