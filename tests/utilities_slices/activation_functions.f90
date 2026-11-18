module utility_slice
implicit none
private
public :: dp,long_int,i64,elu,logistic,elu_logistic,x_times_logistic
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
elemental function elu(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
if (xx >= 0.0_dp) then
   yy = xx
else
   yy = exp(xx) - 1.0_dp
end if
end function elu

elemental function logistic(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 1/(1 + exp(-xx))
end function logistic

elemental function elu_logistic(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = xx*logistic(xx) + (1-logistic(xx))*(exp(xx) - 1.0_dp) 
end function elu_logistic

elemental function x_times_logistic(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = xx*logistic(xx)
end function x_times_logistic

end module
program test_slice
use utility_slice
implicit none
real(dp) :: x(4)
x=[-2.0_dp,-0.5_dp,0.0_dp,2.0_dp]
print *, elu(x)
print *, logistic(x)
print *, elu_logistic(x)
print *, x_times_logistic(x)
end program
