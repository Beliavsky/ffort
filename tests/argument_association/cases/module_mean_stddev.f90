module statistics
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: dp=real64
contains
pure subroutine mean_stddev(x,mean_value,stddev)
real(dp), intent(in) :: x(:)
real(dp), intent(out) :: mean_value,stddev
integer :: i,n
n=size(x)
if(n<1) error stop 'empty sample'
mean_value=0.0_dp
do i=1,n
mean_value=mean_value+x(i)
end do
mean_value=mean_value/real(n)
stddev=0.0_dp
do i=1,n
stddev=stddev+(x(i)-mean_value)**2
end do
stddev=sqrt(stddev/real(n))
end subroutine mean_stddev
end module statistics
program main
use statistics, only : dp,mean_stddev
implicit none
real(dp) :: x(8),m,s
x(1)=2.0_dp
x(2)=4.0_dp
x(3)=4.0_dp
x(4)=4.0_dp
x(5)=5.0_dp
x(6)=5.0_dp
x(7)=7.0_dp
x(8)=9.0_dp
call mean_stddev(x,m,s)
print *,m,s
call mean_stddev(x(8:2:-2),m,s)
print *,m,s
end program main
