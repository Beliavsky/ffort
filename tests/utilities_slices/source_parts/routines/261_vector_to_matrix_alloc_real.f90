subroutine vector_to_matrix_alloc_real(nrow,ncol,yvec,ymat)
integer      , intent(in)               :: nrow,ncol
real(kind=dp), intent(in)               :: yvec(:)
real(kind=dp), intent(out), allocatable :: ymat(:,:)
integer                                 :: nelem
character (len=*), parameter            :: msg="in vector_to_matrix_alloc_real, "
nelem = nrow*ncol
if (size(yvec) /= nelem) then
   write (*,*) msg,"nrow, ncol, nrow*ncol, size(yvec) =",nrow,ncol,nrow*ncol,size(yvec),"need nrow*ncol == size(yvec), STOPPING"
   stop
end if
call set_alloc(reshape(yvec,[nrow,ncol]),ymat)
end subroutine vector_to_matrix_alloc_real
!
