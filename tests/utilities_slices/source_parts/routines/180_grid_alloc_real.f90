subroutine grid_alloc_real(n,xmin,xh,xx)
! allocate a grid of n values, starting at xmin,
! with increments of xh
integer      , intent(in) :: n
real(kind=dp), intent(in) :: xmin,xh
real(kind=dp), allocatable, intent(out) :: xx(:)
integer                   :: i
if (n < 1) then
   allocate (xx(0))
   return 
end if
allocate (xx(n))
forall (i=1:n) xx(i) = xmin + (i-1)*xh
end subroutine grid_alloc_real
!
