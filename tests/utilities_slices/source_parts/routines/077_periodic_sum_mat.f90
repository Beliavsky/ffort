subroutine periodic_sum_mat(nperiod,xx,yy)
! compute cumulative sums of groups of values of xx(:,:)
integer      , intent(in)               :: nperiod
real(kind=dp), intent(in)               :: xx(:,:)
real(kind=dp), intent(out), allocatable :: yy(:,:)
integer                                 :: i,imin,n,ny,ncol
n    = size(xx,1)
ncol = size(xx,2)
if (nperiod < 1 .or. nperiod > n) then
   allocate (yy(0,ncol))
   return
end if
ny = n/nperiod
allocate (yy(ny,ncol))
do i=1,ny
   imin  = 1 + (i-1)*nperiod
   yy(i,:) = sum(xx(imin:imin+nperiod-1,:),dim=1)
end do
end subroutine periodic_sum_mat
!
