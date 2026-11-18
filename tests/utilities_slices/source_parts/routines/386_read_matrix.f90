subroutine read_matrix(iu,xx,ncol_skip)
! read matrix with fixed dimensions from unit iu
integer      , intent(in) :: iu
real(kind=dp), intent(out) :: xx(:,:)
integer      , intent(in), optional :: ncol_skip
integer                             :: i,ncol_skip_
character (len=1), allocatable :: dum(:)
ncol_skip_ = default(0,ncol_skip)
allocate (dum(ncol_skip_))
do i=1,size(xx,1)
   read (iu,*) dum,xx(i,:)
end do
end subroutine read_matrix
!
