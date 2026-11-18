module m
implicit none
integer,parameter::dp=8
contains
elemental function floor_10(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 10.0_dp**(floor(log10(abs(xx)))) * merge(1,-1,xx>0.0_dp)
end function floor_10

elemental function ceiling_10(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 10.0_dp**(ceiling(log10(abs(xx)))) * merge(1,-1,xx>0.0_dp)
end function ceiling_10
end module
program p
use m
implicit none
real(dp)::x(8)=[-1234.0_dp,-12.3_dp,-1.0_dp,-0.014_dp,0.014_dp,1.0_dp,12.3_dp,1234.0_dp]
print *,floor_10(x),ceiling_10(x)
print *,floor_10(reshape(x,[4,2])),ceiling_10(x(8:1:-2))
end program
