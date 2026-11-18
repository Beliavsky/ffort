subroutine moving_average_min_obs(nma,xx,xgood,xma,xma_good,min_obs)
! compute moving average with missing data
integer      , intent(in)  :: nma
real(kind=dp), intent(in)  :: xx(:)       ! (nobs)
logical      , intent(in)  :: xgood(:)    ! (nobs)
real(kind=dp), intent(out) :: xma(:)      ! (nobs)
logical      , intent(out) :: xma_good(:) ! (nobs)
integer      , intent(in)  :: min_obs
integer                    :: sizes(4),nobs,mma,i,i1,i2,min_obs_,ngood
min_obs_ = max(1,min(abs(nma),min_obs))
nobs = size(xx)
sizes = [size(xx),size(xgood),size(xma),size(xma_good)]
if (minval(sizes) /= maxval(sizes)) then
   write (*,*) "in moving_average_min_obs, size(xx),size(xgood),size(xma),size(xma_good)=",sizes," must all be equal, STOPPING"
   stop
end if
xma_good = .false.
xma      = bad_real
if (nma > 0) then ! moving average using current and past data
   do i=max(1,min_obs_),nobs
      i1          = max(1,i-nma+1)
      ngood       = count(xgood(i1:i))
      if (ngood >= min_obs_) then
         xma(i)      = mean(pack(xx(i1:i),xgood(i1:i)))
         xma_good(i) = .true.
      end if
   end do
else if (nma < 0) then ! moving average using current and future data
   mma = abs(nma)
   do i=1,min(nobs,nobs+1-min_obs_)
      i2          = min(nobs,i+mma-1)
      ngood       = count(xgood(i:i2))
      if (ngood >= min_obs_) then
         xma(i)      = mean(pack(xx(i:i2),xgood(i:i2)))
         xma_good(i) = .true.
      end if
   end do
else
   xma      = xx
   xma_good = xgood
end if
end subroutine moving_average_min_obs
!
