module m
contains
subroutine set_alloc(values,x)
character(*),intent(in)::values(:)
character(*),allocatable,intent(inout)::x(:)
if(allocated(x))deallocate(x)
allocate(x(size(values)))
x=values
end subroutine
subroutine select_vec_character(iuse,xx)
integer,intent(in)::iuse(:)
character(*),allocatable,intent(inout)::xx(:)
call set_alloc((xx(iuse)),xx)
end subroutine
end module
program main
use m
implicit none
character(3),allocatable::x(:)
allocate(x(3))
x=[character(3)::'one','two','tri']
call select_vec_character([3,1,3,2],x)
print '(a)',x
end program
