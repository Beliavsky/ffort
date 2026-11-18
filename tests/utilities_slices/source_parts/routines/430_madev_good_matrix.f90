subroutine madev_good_matrix(nma,xx,xgood,xma,xma_good,use_fewer_edge,use_fewer_middle,default_value,nlag)
! compute moving average with missing data for each column of xx(:,:)
integer      , intent(in)  :: nma
real(kind=dp), intent(in)  :: xx(:,:)       ! (nobs,nvar)
logical      , intent(in)  :: xgood(:,:)    ! (nobs,nvar)
real(kind=dp), intent(out) :: xma(:,:)      ! (nobs,nvar)
logical      , intent(out) :: xma_good(:,:) ! (nobs,nvar)
logical      , intent(in), optional :: use_fewer_edge,use_fewer_middle
real(kind=dp), intent(in), optional :: default_value
integer      , intent(in), optional :: nlag
integer                    :: sizes_obs(4),sizes_var(4),nobs,nvar,ivar
logical                    :: use_fewer_edge_
character (len=*), parameter :: msg = "in madev_good_matrix, "
use_fewer_edge_ = default(.false.,use_fewer_edge)
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
   call madev_good(nma,xx(:,ivar),xgood(:,ivar),xma(:,ivar),xma_good(:,ivar), &
                                 use_fewer_edge,use_fewer_middle,default_value,nlag=nlag)
end do
end subroutine madev_good_matrix
!
