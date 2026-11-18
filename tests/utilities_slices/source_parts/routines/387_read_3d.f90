subroutine read_3d(iu,xx,ncol_skip)
integer      , intent(in) :: iu
real(kind=dp), intent(out) :: xx(:,:,:)
integer      , intent(in), optional :: ncol_skip
integer                             :: i1,i2,ncol_skip_
character (len=1), allocatable :: dum(:)
ncol_skip_ = default(0,ncol_skip)
allocate (dum(ncol_skip_))
do i1=1,size(xx,1)
   do i2=1,size(xx,2)
      read (iu,*) dum,xx(i1,i2,:)
   end do
end do
end subroutine read_3d
!
