subroutine copy_alloc_matrix_int(imat,jmat,irow_use,icol_use,irow_excl,icol_excl)
! copy imat to allocatable jmat, optionally using only rows irow_use(:) and columns icol_use(:) and
! excluding rows irow_excl(:) and columns icol_excl(:)
integer, intent(in)               :: imat(:,:)
integer, intent(out), allocatable :: jmat(:,:)
integer, intent(in) , optional    :: irow_use(:),icol_use(:),irow_excl(:),icol_excl(:)
integer, allocatable              :: jrow_use(:),jcol_use(:)
integer                           :: nrow,ncol
nrow = size(imat,1)
ncol = size(imat,2)
call copy_alloc_vec_int(irange(1,nrow),jrow_use,values_include=irow_use,values_exclude=irow_excl)
call copy_alloc_vec_int(irange(1,ncol),jcol_use,values_include=icol_use,values_exclude=icol_excl)
allocate (jmat(size(jrow_use),size(jcol_use)))
jmat = imat(jrow_use,jcol_use)
end subroutine copy_alloc_matrix_int
!
