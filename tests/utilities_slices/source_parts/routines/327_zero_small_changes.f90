subroutine zero_small_changes(xx,min_change,max_change)
! set small changes in xx(:) to zero
real(kind=dp), intent(in out) :: xx(:)
real(kind=dp), intent(in)     :: min_change,max_change
integer                       :: i,n
real(kind=dp)                 :: dx
n = size(xx)
do i=2,n
   dx = xx(i) - xx(i-1)
   if (dx >= min_change .and. dx <= max_change) xx(i) = xx(i-1)
end do
end subroutine zero_small_changes
!
