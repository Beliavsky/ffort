module utility_slice
implicit none
private
public :: dp,long_int,i64,alloc_sub_vec_int
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
subroutine alloc_sub_vec_int(xx,n)
! allocate xx to size n
integer, intent(out), allocatable :: xx(:)
integer, intent(in)               :: n
allocate (xx(max(0,n)))
end subroutine alloc_sub_vec_int

end module
program test_slice
use utility_slice
implicit none
integer,allocatable :: words(:)
call alloc_sub_vec_int(words,2)
print *, size(words)
end program
