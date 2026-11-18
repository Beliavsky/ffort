function duration(xx) result(ndur)
! length of time xx has been consecutively positive or negative
real(kind=dp), intent(in) :: xx(:)
integer                   :: ndur(size(xx))
integer                   :: i,n,old_dur
n = size(xx)
if (n < 1) return
old_dur = 0
do i=1,n
   if (xx(i) > 0) then
      ndur(i) = max(0,old_dur) + 1
   else if (xx(i) < 0) then
      ndur(i) = min(0,old_dur) - 1
   else
      ndur(i) = 0
   end if
   old_dur = ndur(i)
end do
end function duration
!
