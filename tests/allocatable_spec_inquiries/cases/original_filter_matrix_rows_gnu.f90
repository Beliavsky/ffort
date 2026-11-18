module m
implicit none
integer,parameter::dp=kind(1.0d0)
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

function true_pos(mask) result(pos)
logical,intent(in)::mask(:)
integer::pos(count(mask))
integer::i,j
j=0
do i=1,size(mask)
if(mask(i)) then
j=j+1
pos(j)=i
end if
end do
end function
subroutine set_alloc(a,b)
real(dp),intent(in)::a(:,:)
real(dp),allocatable,intent(out)::b(:,:)
allocate(b(size(a,1),size(a,2)))
b=a
end subroutine
end module
program main
use m
real(dp),allocatable::a(:,:)
allocate(a(4,2))
a(:,1)=[1.0_dp,2.0_dp,3.0_dp,4.0_dp]
a(:,2)=[10.0_dp,20.0_dp,30.0_dp,40.0_dp]
call filter_matrix_rows(a,[1],[2.0_dp],[3.0_dp])
if(any(shape(a)/=[2,2])) error stop 1
if(any(a(:,1)/=[2.0_dp,3.0_dp]).or.any(a(:,2)/=[20.0_dp,30.0_dp])) error stop 2
call filter_matrix_rows(a,[1],[2.0_dp],[3.0_dp])
if(size(a,1)/=2) error stop 5
call filter_matrix_rows(a,[integer::],[real(dp)::],[real(dp)::])
if(size(a,1)/=2) error stop 6
call filter_matrix_rows(a,[0],[0.0_dp],[0.0_dp])
if(size(a,1)/=2) error stop 3
call filter_matrix_rows(a,[1],[5.0_dp],[6.0_dp])
if(size(a,1)/=0.or.size(a,2)/=2) error stop 4
print *,1
end
