subroutine fill_previous(xdata,xgood,ydata,ygood)
real(kind=dp), intent(in)  :: xdata(:) ! (n)
logical      , intent(in)  :: xgood(:) ! (n)
real(kind=dp), intent(out) :: ydata(:) ! (n)
logical      , intent(out) :: ygood(:) ! (n)
integer                    :: i,ilast_good,n
n = size(xdata)
if (any([size(xgood),size(ydata),size(ygood)] /= n)) then
   write (*,*) "in util_mod::fill_previous, sizes of xdata, xgood, ydata, ygood are ",n,[size(xgood),size(ydata),size(ygood)], &
               "must be equal, STOPPING"
   stop
end if
ilast_good = 0
ygood      = .false.
ydata      = bad_real
do i=1,n
   if (xgood(i)) ilast_good = i
   if (ilast_good > 0) then
      ydata(i) = xdata(ilast_good)
      ygood(i) = .true.
   end if
end do
end subroutine fill_previous
!
