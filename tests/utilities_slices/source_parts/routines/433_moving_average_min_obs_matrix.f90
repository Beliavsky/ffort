subroutine moving_average_min_obs_matrix(nma,xx,xgood,xma,xma_good,min_obs)
! compute moving average with missing data
integer      , intent(in)    :: nma
real(kind=dp), intent(in)    :: xx(:,:)       ! (nobs,nvar)
logical      , intent(in)    :: xgood(:,:)    ! (nobs,nvar)
real(kind=dp), intent(out)   :: xma(:,:)      ! (nobs,nvar)
logical      , intent(out)   :: xma_good(:,:) ! (nobs,nvar)
integer      , intent(in)    :: min_obs
integer                      :: sizes_obs(4),sizes_var(4),nobs,ivar,nvar
character (len=*), parameter :: msg = "in moving_average_min_obs_matrix, "
nobs = size(xx,1)
nvar = size(xx,2)
sizes_obs = [size(xx,1),size(xgood,1),size(xma,1),size(xma_good,1)]
sizes_var = [size(xx,2),size(xgood,2),size(xma,2),size(xma_good,2)]
if (minval(sizes_obs) /= maxval(sizes_obs)) then
   write (*,*) msg,"size(xx,1),size(xgood,1),size(xma,1),size(xma_good,1)=",sizes_obs," must all be equal, STOPPING"
   stop
else if (minval(sizes_var) /= maxval(sizes_var)) then
   write (*,*) msg,"size(xx,2),size(xgood,2),size(xma,2),size(xma_good,2)=",sizes_var," must all be equal, STOPPING"
   stop
end if
do ivar=1,nvar
   call moving_average_min_obs(nma,xx(:,ivar),xgood(:,ivar),xma(:,ivar),xma_good(:,ivar),min_obs)
end do
end subroutine moving_average_min_obs_matrix
!
