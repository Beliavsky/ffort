subroutine filter_matrix_rows(xx,icol,xmin,xmax)
! keep rows for which the data in columns icol(:) are within xmin(:) and xmax(:)
real(kind=dp), intent(in out), allocatable :: xx(:,:)
integer      , intent(in)                  :: icol(:)          ! (ncol_filter)
real(kind=dp), intent(in)                  :: xmin(:), xmax(:) ! (ncol_filter)
integer                                    :: j,jcol,ncol,ncol_filter
logical                                    :: xmask(size(xx,1))
ncol_filter = size(icol)
if (size(xmin) /= ncol_filter .or. size(xmax) /= ncol_filter) then
   write (*,*) "in util_mod::filter_matrix_rows, size(icol), size(xmin), size(xmax) =", &
               ncol_filter,size(xmin),size(xmax)," must be equal, STOPPING"
   stop
end if
ncol = size(xx,2)
if (ncol_filter < 1) return
xmask = .true.
do j=1,ncol_filter
   jcol = icol(j)
   if (jcol > 0 .and. jcol <= ncol) &
      xmask = xmask .and. xx(:,jcol) >= xmin(j) .and. xx(:,jcol) <= xmax(j)
end do
if (.not. all(xmask)) call set_alloc((xx(true_pos(xmask),:)),xx)
end subroutine filter_matrix_rows
!
