module original_offdiagonal
implicit none
integer,parameter::dp=8
contains
subroutine set_offdiagonal(xod,xx)
! set off-diagonal elements of square matrix x(:,:) to xod
real(kind=dp), intent(in)     :: xod
real(kind=dp), intent(in out) :: xx(:,:)
integer                       :: i,j,n
n = size(xx,1)
if (size(xx,2) /= n) return
do i=1,n
   do j=1,n
      if (i /= j) xx(i,j) = xod
   end do
end do
end subroutine set_offdiagonal
end module
program p
use original_offdiagonal
implicit none
real(dp)::a(3,3),b(2,3),empty(0,0)
a=reshape([1.0_dp,2.0_dp,3.0_dp,4.0_dp,5.0_dp,6.0_dp,7.0_dp,8.0_dp,9.0_dp],[3,3])
call set_offdiagonal(-2.0_dp,a)
print *,a
b=7.0_dp
call set_offdiagonal(0.0_dp,b)
print *,sum(b)
call set_offdiagonal(0.0_dp,empty)
print *,size(empty)
call set_offdiagonal(10.0_dp,a(1:3:2,1:3:2))
print *,a
end program
