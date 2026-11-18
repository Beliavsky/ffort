function vec(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10) result(str)
! return a 1-D character array of the arguments present, assuming that later arguments are not present if earlier ones are missing
character (len=*), intent(in), optional :: s1,s2,s3,s4,s5,s6,s7,s8,s9,s10
character (len=100), allocatable :: str(:)
if (present(s10)) then
   allocate (str(10))
   str(1)=s1; str(2)=s2; str(3)=s3; str(4)=s4; str(5)=s5; str(6)=s6; str(7)=s7; str(8)=s8; str(9)=s9 ; str(10)=s10
else if (present(s9)) then
   allocate (str(9))
   str(1)=s1; str(2)=s2; str(3)=s3; str(4)=s4; str(5)=s5; str(6)=s6; str(7)=s7; str(8)=s8; str(9)=s9
else if (present(s8)) then
   allocate (str(8))
   str(1)=s1; str(2)=s2; str(3)=s3; str(4)=s4; str(5)=s5; str(6)=s6; str(7)=s7; str(8)=s8
else if (present(s7)) then
   allocate (str(7))
   str(1)=s1; str(2)=s2; str(3)=s3; str(4)=s4; str(5)=s5; str(6)=s6; str(7)=s7
else if (present(s6)) then
   allocate (str(6))
   str(1)=s1; str(2)=s2; str(3)=s3; str(4)=s4; str(5)=s5; str(6)=s6
else if (present(s5)) then
   allocate (str(5))
   str(1)=s1; str(2)=s2; str(3)=s3; str(4)=s4; str(5)=s5
else if (present(s4)) then
   allocate (str(4))
   str(1)=s1; str(2)=s2; str(3)=s3; str(4)=s4
else if (present(s3)) then
   allocate (str(3))
   str(1)=s1; str(2)=s2; str(3)=s3
else if (present(s2)) then
   allocate (str(2))
   str(1)=s1; str(2)=s2
else if (present(s1)) then
   allocate (str(1))
   str(1)=s1
else
   allocate (str(0))
end if
end function vec
!
! subroutine returns_good(prices,good_prices,dividends,good_div,method) result(xret)
! real(kind=dp)    , intent(in)           :: prices(:)      ! (n) 
! logical          , intent(in)           :: good_prices(:) ! (n)
! real(kind=dp)    , intent(in), optional :: dividends(:)   ! (n)
! logical          , intent(in), optional :: good_div(:)    ! (n)
! character (len=*), intent(in), optional :: method
! real(kind=dp)                           :: xret(size(prices)-1)
! integer                                 :: i,n
! real(kind=dp)                           :: div_
! character (len=10)                      :: method_
! character (len=*), parameter            :: msg="in returns_good, "
! n=size(prices)
! if (present(dividends)) then
!    if (size(dividends) /= n) then
!        write (*,*) msg,"in returns, size(prices), size(dividends) =",n,size(dividends)," must be equal, STOPPING"
!       stop
!    end if
!    if (.not. present(good_div)) then
!       write (*,*) msg,"dividends PRESENT but good_div not PRESENT, STOPPING"
!       stop
!    else if (size(good_div)) then
!       write (*,*) msg,"size(prices), size(good_div) =",n,size(good_div)," must be equal, STOPPING"
!       stop
!    end if
! end if
! if (present(method)) then
!    method_=method
! else
!    method_=str_simple
! end if
! xret=bad_real
! do i=1,n-1
!    if (present(dividends)) then
!       div_=dividends(i+1)
!    else
!       div_=0.0_dp
!    end if
!    select case (method_)
!       case (str_simple)
!          if (prices(i) /= 0.0_dp) xret(i)=(prices(i+1) + div_)/prices(i) - 1.0_dp
!       case (str_log)
!          if (prices(i) /= 0.0_dp) xret(i)=log((prices(i+1) + div_)/prices(i))
!       case (str_diff)
!          xret(i)=prices(i+1) + div_ - prices(i)
!       case default
!          write (*,*) "in returns, method_=" // trim(method_) // " must be one of " // &
!                     [str_simple,str_log,str_diff] // " STOPPING"
!          stop
!    end select
! end do
! end function returns_good
!
