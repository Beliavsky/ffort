subroutine remove_zero_columns(xmat)
! remove columns of xmat(:,:) for which all elements are zero
real(kind=dp), intent(in out), allocatable :: xmat(:,:)
integer                      , allocatable :: isel(:)
integer                                    :: i,ncol
ncol = size(xmat,2)
allocate (isel(ncol))
isel = 0
do i=1,ncol
   isel(i) = merge(i,0,maxval(abs(xmat(:,i))) > tiny_real)
end do
call set_alloc((xmat(:,pack(isel,isel>0))),xmat)
end subroutine remove_zero_columns
!
