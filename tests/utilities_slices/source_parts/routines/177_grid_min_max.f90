function grid_min_max(n,xmin,xmax) result(xgrid)
! return evenly spaced grid between xmin and xmax, with points at both boundaries
integer      , intent(in) :: n
real(kind=dp), intent(in) :: xmin,xmax
real(kind=dp)             :: xgrid(n)
real(kind=dp)             :: xh
integer                   :: i
if (n < 1) return
xgrid(1) = xmin
if (n < 2) return
xgrid(n) = xmax
xh = (xmax - xmin)/(n-1)
do i=2,n-1
   xgrid(i) = xgrid(i-1) + xh
end do
end function grid_min_max
!
