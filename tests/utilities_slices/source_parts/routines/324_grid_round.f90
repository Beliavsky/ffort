function grid_round(xspacing,x1,x2) result(yy)
! return a grid with with points at multiples of xspacing that contains (x1,x2)
real(kind=dp), intent(in)  :: xspacing,x1,x2
real(kind=dp), allocatable :: yy(:)
real(kind=dp)              :: y1,y2
integer                    :: i,ierr,ny
! y1 = round_up(xspacing,x1)
y1 = round_less(xspacing,x1)
y2 = round_up(xspacing,x2)
ny = nint((y2-y1)/xspacing) + 1
allocate (yy(ny),stat=ierr)
if (ierr /= 0) then
   write (*,*) "in ",mod_name // "::grid_round, could not allocate yy(ny) for ny =",ny
   allocate (yy(0))
   return
end if
forall (i=1:ny) yy(i) = y1 + (i-1)*xspacing
end function grid_round
!
