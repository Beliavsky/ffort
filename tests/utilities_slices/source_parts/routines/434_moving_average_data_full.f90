subroutine moving_average_data_full(nma,xx,xma)
integer      , intent(in)  :: nma
real(kind=dp), intent(in)  :: xx(:)       ! (nobs)
real(kind=dp), intent(out) :: xma(:)      ! (nobs)
integer                    :: i,sizes(2),nobs,mma,i1,i2
nobs = size(xx)
sizes = [nobs,size(xma)]
if (minval(sizes) /= maxval(sizes)) then
   write (*,*) "in moving_average_data, size(xx),size(xma)=",sizes," must all be equal, STOPPING"
   stop
end if
if (nma > 0) then ! moving average using current and past data
   do i=1,nobs
      i1     = max(1,i-nma+1)
      xma(i) = mean(xx(i1:i))
   end do
else if (nma < 0) then ! moving average using current and future data
   mma = abs(nma)
   do i=1,nobs
      i2     = min(nobs,i+mma-1)
      xma(i) = mean(xx(i:i2))
   end do
else
   xma = xx
end if
end subroutine moving_average_data_full
!
