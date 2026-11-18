subroutine combine_matrices(xx,yy,idim,combined)
! combine matrices xx and yy along dimension idim
real(kind=dp), intent(in)  :: xx(:,:),yy(:,:)
integer      , intent(in)  :: idim
real(kind=dp), allocatable, intent(out) :: combined(:,:)
integer                                 :: jdim,nx,ny,nnew,ncommon
character (len=*), parameter            :: msg="in combine_matrices, "
logical                                 :: print_debug_
print_debug_ = .false.
if (idim < 1 .or. idim > 2) then
   allocate (combined(0,0))
   return
end if
nx = size(xx,idim)
ny = size(yy,idim)
nnew  = nx + ny
jdim = 3 - idim
ncommon = size(xx,jdim)
if (size(yy,jdim) /= ncommon) then
   write (*,*) msg,"shape(xx)=",shape(xx)," shape(yy)=",shape(yy),"idim=",idim," not compatible, STOPPING"
   stop
end if
if (idim == 1) then
   allocate (combined(nnew,ncommon))
   combined(:nx,:) = xx
   if (ny > 0) combined(nx+1:,:) = yy
else
   allocate (combined(ncommon,nnew))
   combined(:,:nx) = xx
   if (ny > 0) combined(:,nx+1:) = yy
end if
if (print_debug_) then
   write (*,*) msg," idim =",idim
   write (*,*) "shape(xx)       =",shape(xx)
   write (*,*) "shape(yy)       =",shape(yy)
   write (*,*) "shape(combined) =",shape(combined)
   call print_matrix_simple(xx,title="xx")
   call print_matrix_simple(yy,title="yy")
   call print_matrix_simple(combined,title="combined")
end if
end subroutine combine_matrices
!
