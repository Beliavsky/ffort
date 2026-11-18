subroutine set_alloc_logical_matrix(xx,yy)
logical, intent(in)               :: xx(:,:)
logical, intent(out), allocatable :: yy(:,:)
allocate (yy(size(xx,1),size(xx,2)))
yy = xx
end subroutine set_alloc_logical_matrix
!
