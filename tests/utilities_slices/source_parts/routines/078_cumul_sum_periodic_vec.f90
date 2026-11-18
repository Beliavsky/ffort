function cumul_sum_periodic_vec(xx,nperiod) result(yy)
! compute cumulative sums of groups of values of xx(:)
real(kind=dp), intent(in)  :: xx(:)
integer      , intent(in)  :: nperiod
real(kind=dp), allocatable :: yy(:)
integer                    :: i,imin,n,ny
n = size(xx)
if (nperiod < 1 .or. nperiod > n) then
   allocate (yy(0))
   return
end if
ny = n/nperiod
allocate (yy(ny))
do i=1,ny
   imin  = 1 + (i-1)*nperiod
   yy(i) = sum(xx(imin:imin+nperiod-1))
end do
end function cumul_sum_periodic_vec
!
