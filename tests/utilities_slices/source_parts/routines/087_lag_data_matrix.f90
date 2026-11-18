subroutine lag_data_matrix(nlag,xx,yy)
! return in yy(:,:) the columns of xx(:,:) lagged by nlag elements. yy(1,:) = xx(1-nlag,:) etc.
integer      , intent(in)  :: nlag
real(kind=dp), intent(in)  :: xx(:,:) ! (nobs,ncol)
real(kind=dp), intent(out) :: yy(:,:) ! (nobs,ncol)
integer                    :: i,nobs
nobs = size(xx,1)
if (size(yy,1) /= nobs .or. size(xx,2) /= size(yy,2)) then
   write (*,*) "in util_mod::lag_data_matrix, shape(xx)=",shape(xx)," shape(yy)=",shape(yy), &
               " must have same dimensions, STOPPING"
   stop
end if
if (nobs > 0) then
   forall (i=1:nobs) yy(i,:) = xx(min(nobs,max(1,i-nlag)),:)
end if
end subroutine lag_data_matrix
!
