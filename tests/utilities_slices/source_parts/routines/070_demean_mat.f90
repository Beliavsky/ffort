function demean_mat(xx,cdemean) result(xdm)
! demean each column of xx(:,:)
real(kind=dp), intent(in)  :: xx(:,:)
real(kind=dp), intent(in), optional :: cdemean
real(kind=dp)              :: xdm(size(xx,1),size(xx,2))
integer                    :: icol,ncol,nobs
nobs = size(xx,1)
ncol = size(xx,2)
if (nobs < 1) return
forall (icol=1:ncol) xdm(:,icol) = xx(:,icol) - default(1.0_dp,cdemean)*sum(xx(:,icol))/nobs
end function demean_mat
!
