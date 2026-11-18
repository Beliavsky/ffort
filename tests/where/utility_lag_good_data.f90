module utility_where
implicit none
integer,parameter::dp=kind(1.0d0)
contains
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
end module
program p
use utility_where
real(dp)::x(4)=[1.0_dp,2.0_dp,3.0_dp,4.0_dp],y(4)
logical::m(4)=[.true.,.false.,.true.,.true.],good(4)
call lag_good_data_vec(1,x,m,y,good,-99.0_dp)
print *,y,good
call lag_good_data_vec(-1,x,m,y,good,-99.0_dp)
print *,y,good
call lag_good_data_vec(0,x,m,y,good)
print *,y,good
end program
