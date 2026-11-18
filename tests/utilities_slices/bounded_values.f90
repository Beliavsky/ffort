module utility_slice
implicit none
private
public :: dp,long_int,i64,int_within,real_within,first_pos_positive
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
elemental function int_within(i,i1,i2) result(tf)
integer, intent(in) :: i,i1,i2
logical             :: tf
tf = i >= i1 .and. i <= i2
end function int_within

elemental function real_within(x,x1,x2) result(tf)
real(kind=dp), intent(in) :: x,x1,x2
logical                   :: tf
tf = x >= x1 .and. x <= x2
end function real_within

pure function first_pos_positive(vec) result(ipos)
integer, intent(in) :: vec(:)
integer :: ipos
integer :: i
ipos = 0
do i=1,size(vec)
   if (vec(i) > 0) then
      ipos = i
      return
   end if
end do
end function first_pos_positive

end module
program test_slice
use utility_slice
implicit none
print *, int_within([-1,0,1,2],0,1)
print *, real_within([-1.0_dp,0.0_dp,1.0_dp,2.0_dp],0.0_dp,1.0_dp)
print *, first_pos_positive([-1,0,2])
end program
