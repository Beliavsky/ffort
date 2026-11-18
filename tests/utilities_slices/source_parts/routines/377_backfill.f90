function backfill(xx,good) result(yy)
real(kind=dp), intent(in) :: xx(:) ! (n)
logical      , intent(in) :: good(:)
real(kind=dp)             :: yy(size(xx))
integer                   :: i,n
real(kind=dp)             :: xgood
logical                   :: found_good
n = size(xx)
found_good = .false.
do i=1,n
   if (good(i)) then
      yy(i) = xx(i)
      xgood = xx(i)
      found_good = .true.
   else
      if (found_good) then
         yy(i) = xgood
      else
         yy(i) = bad_real
      end if
   end if
end do
end function backfill
!
