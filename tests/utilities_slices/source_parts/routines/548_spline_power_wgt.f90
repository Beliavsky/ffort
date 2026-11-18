pure function spline_power_wgt(n,power) result(wgt)
! return weights that decay smoothly to zero by lag n+1
integer      , intent(in) :: n
real(kind=dp), intent(in) :: power
real(kind=dp)             :: wgt(n)
integer                   :: i
if (n < 1) return
do i=1,n
   wgt(i) = (n - i + 1) ** power
end do
wgt = wgt/sum(wgt)
end function spline_power_wgt
!
