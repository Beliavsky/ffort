subroutine same_rows_real(irow,xmat,isame,tol,iexcl,include_irow)
! return a list of rows in xmat(:,:) that are the same as xmat(irow,:),
! excluding row irow
integer      , intent(in)               :: irow
real(kind=dp), intent(in)               :: xmat(:,:)
integer      , intent(out), allocatable :: isame(:)  ! list of rows that are the same as xmat(irow,:), excluding irow
real(kind=dp), intent(in) , optional    :: tol       ! tolerance used to determine if rows are equal
integer      , intent(in) , optional    :: iexcl(:)  ! columns to exclude when comparing rows
logical      , intent(in) , optional    :: include_irow
logical                                 :: include_irow_
real(kind=dp)                           :: tol_
integer                                 :: i,nrows
logical                                 :: same(size(xmat,1))
include_irow_ = present_and_true(include_irow)
if (present(tol)) then
   tol_ = tol
else
   tol_ = tiny_real
end if
nrows = size(xmat,1)
same  = .false.
if (irow < 1 .or. irow > nrows) then
   allocate (isame(0))
   return
end if
forall (i=1:nrows) same(i) = ((i /= irow .or. (i == irow .and. include_irow_)) .and. &
                               all_equal_vec_real(xmat(i,:),xmat(irow,:),tol=tol_,iexcl=iexcl))
call true_pos_alloc(same,isame)
end subroutine same_rows_real
!
