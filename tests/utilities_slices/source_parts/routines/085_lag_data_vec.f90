subroutine lag_data_vec(nlag,xx,yy)
! return in yy(:) xx(:) lagged by nlag elements. yy(1) = xx(1-nlag) etc.
integer      , intent(in)  :: nlag
real(kind=dp), intent(in)  :: xx(:) ! (nobs)
real(kind=dp), intent(out) :: yy(:) ! (nobs)
integer                    :: i,nobs
nobs = size(xx)
if (size(yy) /= nobs) then
   write (*,*) "in util_mod::lag_data_vec, size(xx), size(yy) =",size(xx),size(yy)," must be equal, STOPPING"
   stop
end if
if (nobs > 0) then
   forall (i=1:nobs) yy(i) = xx(min(nobs,max(1,i-nlag)))
end if
end subroutine lag_data_vec
!
