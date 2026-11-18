subroutine set_alloc_character_mat(xx,yy)
! for character arrays xx(:,:) and yy(:,:), allocate yy and set it to xx
character (len=*) , intent(in)               :: xx(:,:)
character (len=*) , intent(out), allocatable :: yy(:,:)
allocate (yy(size(xx,1),size(xx,2)))
yy = xx
end subroutine set_alloc_character_mat
!
