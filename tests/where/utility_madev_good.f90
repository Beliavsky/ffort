module utility_where_madev
implicit none
integer,parameter::dp=kind(1.0d0)
interface lag_good_data
module procedure lag_good_data_vec
end interface
contains
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
subroutine check_all_equal(a,message)
integer,intent(in)::a(:)
character(*),intent(in)::message
if(any(a/=a(1))) error stop 1
end subroutine
subroutine moving_average_data_good(nma,xx,xgood,xma,xma_good,use_fewer_edge,use_fewer_middle,default_value)
! Test helper implements exactly the original NMA=0 branch; rejects other modes.
integer,intent(in)::nma
real(dp),intent(in)::xx(:)
logical,intent(in)::xgood(:)
real(dp),intent(out)::xma(:)
logical,intent(out)::xma_good(:)
logical,optional,intent(in)::use_fewer_edge,use_fewer_middle
real(dp),optional,intent(in)::default_value
if(nma/=0) error stop 1
xma=xx
xma_good=xgood
if(present(default_value)) then
   where (.not. xma_good) xma = default_value
end if
end subroutine
end module
program p
use utility_where_madev
real(dp)::x(4)=[2.0_dp,0.0_dp,4.0_dp,6.0_dp],y(4)
logical::m(4)=[.true.,.true.,.false.,.true.],good(4)
call madev_good(0,x,m,y,good,method='ratio')
print *,pack(y,good),good
x=[2.0_dp,3.0_dp,4.0_dp,6.0_dp]
m=.true.
call madev_good(0,x,m,y,good,default_value=-99.0_dp,method='ratio')
print *,y,good
m=[.true.,.true.,.false.,.true.]
call madev_good(0,x,m,y,good,default_value=-99.0_dp,method='diff',nlag=1)
print *,pack(y,good),good
end program
