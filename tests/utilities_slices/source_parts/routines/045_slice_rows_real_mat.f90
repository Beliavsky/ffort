function slice_rows_real_mat(imat,i1,i2) result(jmat)
! return the slice imat(i1:i2,:), avoiding out-of-bounds
! array access
real(kind=dp), intent(in)           :: imat(:,:)
integer      , intent(in), optional :: i1,i2
real(kind=dp), allocatable          :: jmat(:,:)
integer                             :: j1,j2,nj
if (present(i1)) then
   j1 = max(lbound(imat,dim=1),i1)
else
   j1 = lbound(imat,dim=1)
end if
if (present(i2)) then
   j2 = min(ubound(imat,dim=1),i2)
else
   j2 = ubound(imat,dim=1)
end if
nj = j2 - j1 + 1
allocate (jmat(nj,size(imat,2)))
jmat = imat(j1:j2,:)
end function slice_rows_real_mat
!
