subroutine bands(band_inner,band_outer,abs_min,xx,nunch)
! at each time, if position deviation exceeds band_outer,
! trade so that position is within band_inner of target
real(kind=dp), intent(in)     :: band_inner,band_outer
real(kind=dp), intent(in)     :: abs_min ! minimum absolute positions (set smaller positions to zero)
real(kind=dp), intent(in out) :: xx(:)
integer      , intent(out), optional :: nunch
integer                       :: i,n,nunch_
real(kind=dp)                 :: x1,x2
n = size(xx)
nunch_ = 0
do i=2,n
   if (abs(xx(i)) < abs_min) xx(i) = 0.0_dp
   x1 = xx(i) - band_outer
   x2 = xx(i) + band_outer
   if (xx(i-1) < x1) then
      xx(i) = xx(i) - band_inner
   else if (xx(i-1) > x2) then
      xx(i) = xx(i) + band_inner
   else
      xx(i)  = xx(i-1)
      nunch_ = nunch_ + 1
   end if
end do
if (present(nunch)) nunch = nunch_
end subroutine bands
!
