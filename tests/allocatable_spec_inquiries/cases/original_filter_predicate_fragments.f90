module m
implicit none
integer,parameter::dp=kind(1.0d0)
contains
subroutine retained_mask(xx,icol,xmin,xmax,result_mask)
logical,intent(out)::result_mask(:)
real(kind=dp), intent(in out), allocatable :: xx(:,:)
integer      , intent(in)                  :: icol(:)          ! (ncol_filter)
real(kind=dp), intent(in)                  :: xmin(:), xmax(:) ! (ncol_filter)
integer                                    :: j,jcol,ncol,ncol_filter
logical                                    :: xmask(size(xx,1))
ncol_filter = size(icol)
ncol = size(xx,2)
if (ncol_filter < 1) return
xmask = .true.
do j=1,ncol_filter
   jcol = icol(j)
   if (jcol > 0 .and. jcol <= ncol) &
      xmask = xmask .and. xx(:,jcol) >= xmin(j) .and. xx(:,jcol) <= xmax(j)
end do
result_mask=xmask
end subroutine
end module
program main
use m
real(dp),allocatable::data(:,:)
logical::result_mask(4)
allocate(data(4,2))
data(:,1)=[1.0_dp,2.0_dp,3.0_dp,4.0_dp]
data(:,2)=[10.0_dp,20.0_dp,30.0_dp,40.0_dp]
call retained_mask(data,[1,2,0],[2.0_dp,0.0_dp,100.0_dp],[4.0_dp,30.0_dp,0.0_dp],result_mask)
if(any(result_mask.neqv.[.false.,.true.,.true.,.false.])) error stop 1
if(any(shape(data)/=[4,2])) error stop 2
print *,1
end
