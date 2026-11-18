module original_filter
implicit none
integer,parameter::dp=kind(1.0d0)
interface true_pos
module procedure true_pos_func
end interface
interface set_alloc
module procedure set_alloc_real_matrix
end interface
contains
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

function true_pos_func(tf) result(ipos)
! return in ipos the positions of the true elements in tf(:)
logical, intent(in) :: tf(:)
integer             :: ipos(count(tf))
integer             :: i,j
j = 0
do i=1,size(tf)
   if (tf(i)) then
      j = j + 1
      ipos(j) = i
   end if
end do
end function true_pos_func

subroutine set_alloc_real_matrix(xx,yy)
! for real matrices xx(:,:) and yy(:,:), allocate yy and set it to xx
real(kind=dp) , intent(in)               :: xx(:,:)
real(kind=dp) , intent(out), allocatable :: yy(:,:)
allocate (yy(size(xx,1),size(xx,2)))
yy = xx
end subroutine set_alloc_real_matrix

end module
