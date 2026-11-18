subroutine set_alloc_logical_vec(xx,yy)
logical, intent(in) :: xx(:)
logical, intent(out), allocatable :: yy(:)
integer             :: n
n = size(xx)
allocate (yy(n))
yy = xx
end subroutine set_alloc_logical_vec
!
