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

program main
use black_scholes_module, only : dp, black_scholes_price
implicit none

real(dp) :: c, p, expected, tolerance
c=black_scholes_price(100.0_dp, 100.0_dp, -0.10000000000000001_dp, 0.20000000000000001_dp, 2.0_dp, .true.)
p=black_scholes_price(100.0_dp, 100.0_dp, -0.10000000000000001_dp, 0.20000000000000001_dp, 2.0_dp, .false.)
expected=1.00000000000000000e+02_dp - 1.00000000000000000e+02_dp*exp(-(-1.00000000000000006e-01_dp)*2.00000000000000000e+00_dp)
tolerance=1.0e-12_dp*max(1.0_dp,abs(c),abs(p),abs(expected))
if(abs(c-p-expected)>tolerance) error stop 'parity'
print *,c,p
end program main
