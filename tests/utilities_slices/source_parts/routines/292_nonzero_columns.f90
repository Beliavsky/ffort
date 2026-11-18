function nonzero_columns(xmat,thresh) result(icol)
! return in icol(:) the locations of the columns in xmat that have any nonzero elements
real(kind=dp), intent(in)           :: xmat(:,:)
real(kind=dp), intent(in), optional :: thresh
integer      , allocatable          :: icol(:)
integer                             :: i,ncol
real(kind=dp)                       :: thresh_
thresh_ = default(tiny_real,thresh)
ncol    = size(xmat,2)
allocate (icol(ncol))
icol = 0
do i=1,ncol
   if (any(abs(xmat(:,i)) > thresh_)) icol(i) = i
end do
call set_alloc(pack(icol,icol>0),icol)
end function nonzero_columns
!
