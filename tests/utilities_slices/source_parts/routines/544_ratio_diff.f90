function ratio_diff(x) result(y)
! return the ratios of consecutive elements of x(:) minus 1
real(kind=dp), intent(in) :: x(:)
real(kind=dp)             :: y(size(x)-1)
integer                   :: n
n = size(x)
if (n > 1) y = x(2:)/x(:n-1) - 1.0_dp
end function ratio_diff
!
