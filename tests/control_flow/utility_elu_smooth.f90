module utility_slice
implicit none
private
public :: dp,long_int,i64,elu_smooth
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
elemental function elu_smooth(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
real(kind=dp)             :: c
if (xx >= 0.0_dp) then
   yy = xx
else if (xx >= -1.0_dp) then
   c  = 1.0_dp + xx
   yy = c*xx + (1-c)*(exp(xx) - 1.0_dp)    
else
   yy = exp(xx) - 1.0_dp
end if
end function elu_smooth

end module
program test_slice
use utility_slice
implicit none
print *, elu_smooth([-2.0_dp,-1.0_dp,-0.5_dp,0.0_dp,1.0_dp])
end program
