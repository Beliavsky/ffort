module black_scholes_module
   use, intrinsic :: iso_fortran_env, only : real64
   implicit none
   private
   integer, parameter, public :: dp = real64
   public :: black_scholes_price

contains

   real(dp) function black_scholes_price(spot, strike, rate, volatility, maturity, is_call) result(price)
      real(dp), intent(in) :: spot        ! Current underlying price, > 0
      real(dp), intent(in) :: strike      ! Exercise price, > 0
      real(dp), intent(in) :: rate        ! Continuously compounded annual risk-free rate
      real(dp), intent(in) :: volatility  ! Annualized volatility, >= 0
      real(dp), intent(in) :: maturity    ! Time to expiration in years, >= 0
      logical, intent(in)  :: is_call     ! .true. for call, .false. for put
      real(dp) :: d1, d2, discounted_strike

      if (spot <= 0.0_dp .or. strike <= 0.0_dp) error stop 'Spot and strike must be positive'
      if (volatility < 0.0_dp .or. maturity < 0.0_dp) error stop 'Volatility and maturity must be nonnegative'

      if (maturity <= 0.0_dp) then
         if (is_call) then
            price = max(spot - strike, 0.0_dp)
         else
            price = max(strike - spot, 0.0_dp)
         end if
         return
      end if

      discounted_strike = strike * exp(-rate * maturity)
      if (volatility <= 0.0_dp) then
         if (is_call) then
            price = max(spot - discounted_strike, 0.0_dp)
         else
            price = max(discounted_strike - spot, 0.0_dp)
         end if
         return
      end if

      d1 = (log(spot / strike) + (rate + 0.5_dp * volatility**2) * maturity) / &
           (volatility * sqrt(maturity))
      d2 = d1 - volatility * sqrt(maturity)

      if (is_call) then
         price = spot * normal_cdf(d1) - discounted_strike * normal_cdf(d2)
      else
         price = discounted_strike * normal_cdf(-d2) - spot * normal_cdf(-d1)
      end if
   end function black_scholes_price

   pure real(dp) function normal_cdf(x) result(probability)
      real(dp), intent(in) :: x ! Standard normal deviate
      probability = 0.5_dp * erfc(-x / sqrt(2.0_dp))
   end function normal_cdf

end module black_scholes_module

program test_black_scholes
   use black_scholes_module, only : dp, black_scholes_price
   implicit none
   real(dp), parameter :: benchmark_call = 10.450583572185565_dp
   real(dp), parameter :: benchmark_put  = 5.573526022256971_dp
   real(dp) :: call_price, put_price

   call test_case('At the money', 100.0_dp, 100.0_dp, 0.05_dp, 0.20_dp, 1.0_dp)
   call test_case('In the money call', 120.0_dp, 100.0_dp, 0.03_dp, 0.30_dp, 0.5_dp)
   call test_case('Zero volatility', 100.0_dp, 110.0_dp, 0.05_dp, 0.0_dp, 2.0_dp)
   call test_case('At expiration', 95.0_dp, 100.0_dp, 0.05_dp, 0.20_dp, 0.0_dp)

   call_price = black_scholes_price(100.0_dp, 100.0_dp, 0.05_dp, 0.20_dp, 1.0_dp, .true.)
   put_price  = black_scholes_price(100.0_dp, 100.0_dp, 0.05_dp, 0.20_dp, 1.0_dp, .false.)
   if (abs(call_price - benchmark_call) > 1.0e-10_dp) error stop 'Call benchmark test failed'
   if (abs(put_price  - benchmark_put)  > 1.0e-10_dp) error stop 'Put benchmark test failed'

   print '(a)', 'All put-call parity and benchmark tests passed.'

contains

   subroutine test_case(description, spot, strike, rate, volatility, maturity)
      character(len=*), intent(in) :: description ! Name of test case
      real(dp), intent(in) :: spot                 ! Underlying price
      real(dp), intent(in) :: strike               ! Strike price
      real(dp), intent(in) :: rate                 ! Annual continuously compounded rate
      real(dp), intent(in) :: volatility           ! Annual volatility
      real(dp), intent(in) :: maturity             ! Time to expiration in years
      real(dp) :: call_value, put_value, lhs, rhs, tolerance

      call_value = black_scholes_price(spot, strike, rate, volatility, maturity, .true.)
      put_value  = black_scholes_price(spot, strike, rate, volatility, maturity, .false.)
      lhs = call_value - put_value
      rhs = spot - strike * exp(-rate * maturity)
      tolerance = 1.0e-12_dp * max(1.0_dp, abs(call_value), abs(put_value), abs(rhs))

      print '(a)', description
      print '(a,f16.10)', '  Call:        ', call_value
      print '(a,f16.10)', '  Put:         ', put_value
      print '(a,es12.4)', '  Parity error: ', lhs - rhs
      if (abs(lhs - rhs) > tolerance) error stop 'Put-call parity failed'
   end subroutine test_case

end program test_black_scholes
