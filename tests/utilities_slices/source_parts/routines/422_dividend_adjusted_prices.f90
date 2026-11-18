function dividend_adjusted_prices(prices,dividends) result(xadj)
real(kind=dp), intent(in) :: prices(:)          ! (n)
reaL(kind=dp), intent(in) :: dividends(:)       ! (n)
real(kind=dp)             :: xadj(size(prices)) ! (n)
integer                   :: i,n
real(kind=dp)             :: wratio(size(prices)) ! wealth relative
n = size(prices)
if (size(dividends) /= n) then
   print*,"in dividend_adjusted_prices, size(prices), size(dividends) =",n,size(dividends)," must be equal, STOPPING"
   stop
end if
wratio = 1.0_dp
do i=2,n
   if (prices(i-1) /= 0.0_dp) wratio(i) = (prices(i) + dividends(i))/prices(i-1)
end do
do i=n,1,-1
   if (i == n) then
      xadj(i) = prices(i)
   else if (wratio(i+1) /= 0.0_dp) then
      xadj(i) = xadj(i+1)/wratio(i+1)
   else
      xadj(i) = prices(i)
   end if
end do
end function dividend_adjusted_prices
!
