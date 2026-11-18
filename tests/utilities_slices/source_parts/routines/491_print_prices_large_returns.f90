subroutine print_prices_large_returns(xx,thresh_low,thresh_high,icol_price,scale_ret,outu)
real(kind=dp), intent(in)           :: xx(:,:)
real(kind=dp), intent(in)           :: thresh_low,thresh_high
integer      , intent(in)           :: icol_price
real(kind=dp), intent(in), optional :: scale_ret
integer      , intent(in), optional :: outu
integer                             :: i,j,outu_,nret
real(kind=dp), allocatable          :: xret(:)
outu_ = default(istdout,outu)
nret = size(xx,1) - 1
if (nret < 1) return
call set_alloc(xx(2:,icol_price)/xx(:nret,icol_price)-1.0_dp,xret)
if (present(scale_ret)) xret = scale_ret*xret
do i=1,nret
   if (xret(i) < thresh_low .or. xret(i) > thresh_high) then
      write (outu_,"(/,'return = ',f14.4)") xret(i)
      do j=i,i+1
         write (outu_,"(100f14.4)") xx(j,:)         
      end do
   end if
end do
end subroutine print_prices_large_returns
!
