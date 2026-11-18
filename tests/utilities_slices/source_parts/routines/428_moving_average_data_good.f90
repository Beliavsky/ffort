subroutine moving_average_data_good(nma,xx,xgood,xma,xma_good,use_fewer_edge,use_fewer_middle,default_value)
! compute moving average with missing data
integer      , intent(in)  :: nma
real(kind=dp), intent(in)  :: xx(:)       ! (nobs)
logical      , intent(in)  :: xgood(:)    ! (nobs)
real(kind=dp), intent(out) :: xma(:)      ! (nobs)
logical      , intent(out) :: xma_good(:) ! (nobs)
logical      , intent(in), optional :: use_fewer_edge,use_fewer_middle
real(kind=dp), intent(in), optional :: default_value
integer                    :: sizes(4),nobs,mma,i,i1,i2
logical                    :: use_fewer_edge_,use_fewer_middle_
use_fewer_edge_   = default(.false.,use_fewer_edge)
use_fewer_middle_ = default(.false.,use_fewer_middle)
nobs = size(xx)
sizes = [size(xx),size(xgood),size(xma),size(xma_good)]
if (minval(sizes) /= maxval(sizes)) then
   write (*,*) "size(xx),size(xgood),size(xma),size(xma_good)=",sizes," must all be equal, STOPPING"
   stop
end if
xma_good = .false.
if (nma > 0) then ! moving average using current and past data
   do i=merge(1,nma,use_fewer_edge_),nobs
      i1          = max(1,i-nma+1)
      xma(i)      = mean(xx(i1:i))
      if (use_fewer_middle_) then
         xma_good(i) = any(xgood(i1:i))
      else
         xma_good(i) = all(xgood(i1:i))
      end if
   end do
else if (nma < 0) then ! moving average using current and future data
   mma = abs(nma)
   do i=1,merge(nobs,nobs-mma+1,use_fewer_edge_)
      i2          = min(nobs,i+mma-1)
      xma(i)      = mean(xx(i:i2))
      if (use_fewer_middle_) then
         xma_good(i) = any(xgood(i:i2))
      else
         xma_good(i) = all(xgood(i:i2))
      end if
   end do
else
   xma      = xx
   xma_good = xgood
end if
if (present(default_value)) then
   where (.not. xma_good) xma = default_value
end if
end subroutine moving_average_data_good
!
