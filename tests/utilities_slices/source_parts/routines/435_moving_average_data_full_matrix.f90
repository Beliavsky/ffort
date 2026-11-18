subroutine moving_average_data_full_matrix(nma,xx,xma)
integer      , intent(in)  :: nma
real(kind=dp), intent(in)  :: xx(:,:)     ! (nobs,nvar)
real(kind=dp), intent(out) :: xma(:,:)    ! (nobs,nvar)
integer                    :: ivar,nvar,sizes_obs(2),sizes_var(2),nobs
character (len=*), parameter :: msg = "in moving_average_data_matrix, "
nobs = size(xx,1)
nvar = size(xx,2)
sizes_obs = [nobs,size(xma,1)]
sizes_var = [nvar,size(xma,2)]
if (minval(sizes_obs) /= maxval(sizes_obs)) then
   write (*,*) msg,"size(xx,1),size(xma,1)=",sizes_obs," must be equal, STOPPING"
   stop
else if (minval(sizes_var) /= maxval(sizes_var)) then
   write (*,*) msg,"size(xx,2),size(xma,2)=",sizes_var," must be equal, STOPPING"
   stop
end if
do ivar=1,nvar
   call moving_average_data_full(nma,xx(:,ivar),xma(:,ivar))
end do
end subroutine moving_average_data_full_matrix
!
