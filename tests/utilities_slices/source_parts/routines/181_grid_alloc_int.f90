subroutine grid_alloc_int(n,xmin,xh,xx)
! allocate a grid of n values, starting at xmin,
! with increments of xh
integer, intent(in)               :: n
integer, intent(in)               :: xmin,xh
integer, allocatable, intent(out) :: xx(:)
integer                           :: i
if (n < 1) then
   allocate (xx(0))
   return
end if
allocate (xx(n))
forall (i=1:n) xx(i) = xmin + (i-1)*xh
end subroutine grid_alloc_int
!
