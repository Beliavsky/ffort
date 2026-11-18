function fill_bad(xx,xgood) result(yy)
real(kind=dp), intent(in) :: xx(:)
logical      , intent(in) :: xgood(:)
real(kind=dp)             :: yy(size(xx))
integer                   :: i
real(kind=dp)             :: last_good
last_good = 0.0_dp
do i=1,size(xx)
   if (xgood(i)) then
      last_good = xx(i)
      yy(i) = xx(i)
   else
      yy(i) = last_good
   end if
end do
end function fill_bad
!
