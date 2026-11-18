subroutine lag_good_data_vec(nlag,xx,xgood,yy,ygood,ydefault)
integer      , intent(in)  :: nlag
real(kind=dp), intent(in)  :: xx(:)    ! (nobs)
logical      , intent(in)  :: xgood(:) ! (nobs)
logical      , intent(out) :: ygood(:) ! (nobs)
real(kind=dp), intent(out) :: yy(:)    ! (nobs)
real(kind=dp), intent(in), optional :: ydefault
integer                    :: i,j,nobs
call check_all_equal([size(xx),size(xgood),size(yy),size(ygood)], &
                     "in util_mod::lag_good_data_vec, size(xx), size(xgood), size(yy), size(ygood) =")
nobs = size(xx)
do i=1,nobs
   j = i + nlag
   if (j > 0 .and. j <= nobs) then
      yy(i)    = xx(j)
      ygood(i) = xgood(j)
   else
      ygood(i) = .false.
   end if
end do
if (present(ydefault)) then
   where (.not. ygood) yy = ydefault
end if
end subroutine lag_good_data_vec
!
