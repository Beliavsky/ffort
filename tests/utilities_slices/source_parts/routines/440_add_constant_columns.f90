function add_constant_columns(xmat,xconst) result(ymat)
real(kind=dp), intent(in) :: xmat(:,:)
real(kind=dp), intent(in) :: xconst(:)
real(kind=dp)             :: ymat(size(xmat,1),size(xmat,2) + size(xconst))
integer                   :: icol_add,ncol_x
ncol_x = size(xmat,2)
ymat(:,:ncol_x) = xmat
forall (icol_add=1:size(xconst)) ymat(:,ncol_x+icol_add) = xconst(icol_add)
end function add_constant_columns
!
