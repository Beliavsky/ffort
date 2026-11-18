subroutine set_alloc_integer_matrix(xx,yy)
! for integer matrices xx(:,:) and yy(:,:), allocate yy and set it to xx
integer , intent(in)               :: xx(:,:)
integer , intent(out), allocatable :: yy(:,:)
allocate (yy(size(xx,1),size(xx,2)))
yy = xx
end subroutine set_alloc_integer_matrix
!
