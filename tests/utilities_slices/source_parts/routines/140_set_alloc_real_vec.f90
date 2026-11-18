subroutine set_alloc_real_vec(xx,yy,nsize)
! for real vectors xx(:) and yy(:), allocate yy and set it to xx
real(kind=dp), intent(in)               :: xx(:)
real(kind=dp), intent(out), allocatable :: yy(:)
integer      , intent(out), optional    :: nsize
integer                                 :: ni
ni = size(xx)
allocate (yy(ni))
yy = xx
if (present(nsize)) nsize = ni
end subroutine set_alloc_real_vec
!
