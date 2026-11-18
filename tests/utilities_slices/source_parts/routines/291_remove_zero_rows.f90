subroutine remove_zero_rows(xmat)
! remove rows of xmat(:,:) for which all elements are zero
real(kind=dp), intent(in out), allocatable :: xmat(:,:)
integer                      , allocatable :: isel(:)
integer                                    :: i,nrows
nrows = size(xmat,1)
allocate (isel(nrows))
isel = 0
do i=1,nrows
   isel(i) = merge(i,0,maxval(abs(xmat(i,:))) > tiny_real)
end do
call set_alloc((xmat(pack(isel,isel>0),:)),xmat)
end subroutine remove_zero_rows
!
