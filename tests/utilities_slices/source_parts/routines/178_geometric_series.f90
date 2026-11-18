pure function geometric_series(n,a,r,normalize) result(yy)
integer      , intent(in) :: n ! # of terms of series
real(kind=dp), intent(in) :: a ! first term of series
real(kind=dp), intent(in) :: r ! common ratio
logical      , intent(in), optional :: normalize
real(kind=dp)             :: yy(n)
real(kind=dp)             :: ysum
integer                   :: i
if (n < 1) return
yy(1) = a
do i=2,n
   yy(i) = r*yy(i-1)
end do
if (present(normalize)) then
   if (normalize) then
      ysum = sum(yy)
      if (ysum /= 0.0_dp) yy = yy/ysum
   end if
end if
end function geometric_series
!
