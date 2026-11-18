pure function open_grid(n,xmin,xmax) result(xx)
! uniform grid between xmin and xmax with points NOT
! placed at xmin or xmax
integer      , intent(in) :: n
real(kind=dp), intent(in) :: xmin,xmax
real(kind=dp)             :: xx(n)
real(kind=dp)             :: dx
integer                   :: i
if (n < 1) return
dx = (xmax - xmin)/(n+1)
forall (i=1:n) xx(i) = xmin + (i*dx)
end function open_grid
!
