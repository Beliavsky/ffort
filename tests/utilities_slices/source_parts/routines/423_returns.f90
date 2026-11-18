function returns(prices,dividends,method) result(xret)
real(kind=dp)    , intent(in)           :: prices(:)
real(kind=dp)    , intent(in), optional :: dividends(:)
character (len=*), intent(in), optional :: method
real(kind=dp)                           :: xret(size(prices)-1)
integer                                 :: i,n
real(kind=dp)                           :: div_
character (len=10)                      :: method_
n = size(prices)
if (present(dividends)) then
   if (size(dividends) /= n) then
      print*,"in returns, size(prices), size(dividends) =",n,size(dividends)," must be equal, STOPPING"
      stop
   end if
end if
if (present(method)) then
   method_ = method
else
   method_ = str_simple
end if
xret = bad_real
do i=1,n-1
   if (present(dividends)) then
      div_ = dividends(i+1)
   else
      div_ = 0.0_dp
   end if
   select case (method_)
      case (str_simple)
         if (prices(i) /= 0.0_dp) xret(i) = (prices(i+1) + div_)/prices(i) - 1.0_dp
      case (str_log)
         if (prices(i) /= 0.0_dp) xret(i) = log((prices(i+1) + div_)/prices(i))
      case (str_diff)
         xret(i) = prices(i+1) + div_ - prices(i)
      case default
         write (*,*) "in returns, method_ = " // trim(method_) // " must be one of " // &
                    [str_simple,str_log,str_diff] // " STOPPING"
         stop
   end select
end do
end function returns
!
