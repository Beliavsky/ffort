module m
integer,parameter::dp=8
contains
subroutine alloc_sub_vec_real(xx,n)
! allocate xx to size n
real(kind=dp), intent(out), allocatable :: xx(:)
integer      , intent(in)               :: n
allocate (xx(max(0,n)))
end subroutine alloc_sub_vec_real
subroutine alloc_sub_vec_int(xx,n)
! allocate xx to size n
integer, intent(out), allocatable :: xx(:)
integer, intent(in)               :: n
allocate (xx(max(0,n)))
end subroutine alloc_sub_vec_int
end module
program main
use m
real(8),allocatable::x(:)
integer,allocatable::y(:)
call alloc_sub_vec_real(x,3)
x=2.0_8
call alloc_sub_vec_int(y,2)
y=7
print *,size(x),sum(x),size(y),sum(y)
call alloc_sub_vec_real(x,-2)
call alloc_sub_vec_int(y,0)
print *,allocated(x),size(x),allocated(y),size(y)
end program
