subroutine madev_good(nma,xx,xgood,xmadev,xmadev_good,use_fewer_edge,use_fewer_middle,default_value,method,nlag)
! compute moving average deviation with missing data
integer      , intent(in)  :: nma
real(kind=dp), intent(in)  :: xx(:)       ! (nobs)
logical      , intent(in)  :: xgood(:)    ! (nobs)
real(kind=dp), intent(out) :: xmadev(:)      ! (nobs)
logical      , intent(out) :: xmadev_good(:) ! (nobs)
logical      , intent(in), optional :: use_fewer_edge,use_fewer_middle
real(kind=dp), intent(in), optional :: default_value
character (len=*), intent(in), optional :: method ! ("diff","ratio")
integer          , intent(in), optional :: nlag
real(kind=dp)              :: xma(size(xx))
logical                    :: xma_good(size(xx))
character (len=10)         :: method_
if (present(method)) then
   method_ = trim(method)
else
   method_ = "diff"
end if
call moving_average_data_good(nma,xx,xgood,xma,xma_good,use_fewer_edge,use_fewer_middle,default_value)
if (method_ == "ratio") then
   xmadev_good = xgood .and. xma_good .and. (xma /= 0.0_dp)
   where (xmadev_good) xmadev = xx/xma - 1.0_dp
   if (present(default_value)) xmadev = merge(xmadev,default_value,xmadev_good)
else if (method_ == "diff") then
   xmadev      = xx - xma
   xmadev_good = xgood .and. xma_good
   if (present(default_value)) xmadev = merge(xmadev,default_value,xmadev_good)
end if
if (present(nlag)) then
   call lag_good_data(nlag,(xmadev),(xmadev_good),xmadev,xmadev_good)
end if
end subroutine madev_good
!
