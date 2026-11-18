subroutine remove_duplicate_columns(xmat,thresh,isel)
! remove columns of xmat(:,:) whose elements are the same as other another column
real(kind=dp), intent(in out), allocatable           :: xmat(:,:)
real(kind=dp), intent(in)    , optional              :: thresh
integer      , intent(out)   , optional, allocatable :: isel(:)
real(kind=dp)                              :: thresh_
integer                      , allocatable :: jsel(:)
integer                                    :: i,j,ncol
logical                                    :: duplicate
ncol = size(xmat,2)
if (ncol < 1) return
thresh_ = default(tiny_real,thresh)
allocate (jsel(ncol))
jsel    = 0
jsel(1) = 1
do i=2,ncol
   duplicate = .false.
   do j=1,i-1
      if (all(abs(xmat(:,i)-xmat(:,j)) <= thresh_)) then
         duplicate = .true.
         exit
      end if
   end do
   jsel(i) = merge(0,i,duplicate)
end do
call set_alloc((xmat(:,pack(jsel,jsel>0))),xmat)
if (present(isel)) call set_alloc(pack(jsel,jsel>0),isel)
end subroutine remove_duplicate_columns
!
