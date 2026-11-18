subroutine interpolate_vec(good,xorig,xx)
! interpolate data using average of data before and after
logical      , intent(in)  :: good(:)
real(kind=dp), intent(in)  :: xorig(:)
real(kind=dp), intent(out) :: xx(:)
integer                    :: i,ibef,iaft,n
n = size(good)
if (any([size(xorig), size(xx)] /= n)) then
   write (*,*) "in interpolate_vec, size(good), size(xorig), size(xx) =", &
               n,size(xorig),size(xx)," must be equal, STOPPING"
   stop
end if
do i=1,n
   if (good(i)) then
      xx(i) = xorig(i)
   else
      ibef = last_true(good(:i-1))
      iaft = first_true(good(i+1:))
      if (iaft /= 0) iaft = iaft + i
      if (ibef > 0 .and. iaft > 0) then
         xx(i) = (xorig(ibef) + xorig(iaft))/2
      else if (ibef > 0) then
         xx(i) = xorig(ibef)
      else if (iaft > 0) then
         xx(i) = xorig(iaft)
      end if
   end if
end do
end subroutine interpolate_vec
!
