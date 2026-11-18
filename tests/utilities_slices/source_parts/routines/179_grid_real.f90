function grid_real(n,xmin,xh) result(xx)
! return a grid of n values, starting at xmin,
! with increments of xh
integer      , intent(in) :: n
real(kind=dp), intent(in), optional :: xmin,xh
real(kind=dp)             :: xx(n)
integer                   :: i
forall (i=1:n) xx(i) = default(1.0_dp,xmin) + (i-1)*default(1.0_dp,xh)
end function grid_real
!
