function pos_changes(xx) result(ipos)
! return positions of the first value and of positions with values different from the previous value
real(kind=dp), intent(in) :: xx(:)
integer, allocatable :: ipos(:)
integer              :: n
n = size(xx)
if (n == 0) then
   allocate(ipos(0))
   return
end if
ipos = true_pos([.true.,xx(2:) /= xx(:n-1)])
end function pos_changes
!
! function pos_changes_real(xx) result(ipos)
! real(kind=dp), intent(in)  :: xx(:)
! integer      , allocatable
! end function pos_changes_real
!
! function rows_real(xx,tf) result(yy)
! real(kind=dp), intent(in) :: xx(:,:)
! logical      , intent(in) :: tf(:)
! real(kind=dp)             :: yy(count(tf),size(xx,2))
! integer                   ::
! yy = 0.0_dp
! end function rows_real
