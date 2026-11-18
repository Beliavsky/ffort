recursive function moving_average_xlen(xx,xlen) result(xma)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: xlen
real(kind=dp)             :: xma(size(xx))
integer                   :: i,i1,nma,n,nma_floor
real(kind=dp)             :: wgt_last,xdiv
n    = size(xx)
if (xlen > n) then
   xma = moving_average_xlen(xx,real(n,kind=dp))
   return
end if
nma  = ceiling(xlen)
xdiv = abs(xlen)
xma  = 0.0_dp
if (nma <= n .and. n > 1) then
   nma_floor = nma - 1
   wgt_last  = xlen - nma_floor
!   print*,"xlen, xdiv, nma_floor, wgt_last =",xlen,xdiv,nma_floor,wgt_last
   do i=1,n
      if (i <= nma_floor) then
         xma(i) = mean(xx(:i))
      else
         i1     = i - nma_floor + 1
         xma(i) = (sum(xx(i1:i)) + wgt_last*xx(i1-1))/xdiv
      end if
   end do
end if
end function moving_average_xlen
!
