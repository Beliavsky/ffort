pure function weighted_sums(xx,wgt) result(xma)
! products of xx(i-nwgt+1:i) and wgt(nwgt:1:-1)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: wgt(:)
real(kind=dp)             :: xma(size(xx))
integer                   :: i,n,nwgt
xma = 0.0_dp
n = size(xx)
nwgt = size(wgt)
if (n < 1 .or. nwgt < 1 .or. nwgt > n) return
do i=nwgt,n
   xma(i) = sum(wgt(nwgt:1:-1)*xx(i-nwgt+1:i))
end do
end function weighted_sums
!
