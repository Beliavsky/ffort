module utility_slice
implicit none
private
public :: dp,long_int,i64,first_pos_ge_int,first_pos_ge_real
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
pure function first_pos_ge_int(ivec,ival) result(ipos)
! return the position of the first element of ivec(:) that is >= ival,
! n+1 if none are >= ival
integer, intent(in) :: ivec(:),ival
integer             :: ipos
integer             :: i,n
n    = size(ivec)
ipos = n+1
do i=1,n
   if (ivec(i) >= ival) then
      ipos = i
      exit
   end if
end do
end function first_pos_ge_int

pure function first_pos_ge_real(xvec,xval) result(ipos)
! return the position of the first element of xvec(:) that is >= xval,
! n+1 if none are >= xval
real(kind=dp), intent(in) :: xvec(:),xval
integer                   :: ipos
integer                   :: i,n
n    = size(xvec)
ipos = n+1
do i=1,n
   if (xvec(i) >= xval) then
      ipos = i
      exit
   end if
end do
end function first_pos_ge_real

end module
program test_slice
use utility_slice
implicit none
integer :: empty(0)
print *, first_pos_ge_int([1,3,5,7],4),first_pos_ge_int([1,3,5,7],8)
print *, first_pos_ge_real([1.0_dp,3.0_dp,5.0_dp],3.0_dp)
print *, first_pos_ge_int(empty,3),first_pos_ge_int([1,3,5],0)
end program
