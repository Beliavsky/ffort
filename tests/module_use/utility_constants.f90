module kind_mod
implicit none
private
public :: dp,bad_real,long_int,i32,i64,bad_int
integer, parameter :: sp = selected_real_kind(6, 37)   ! single precision
integer, parameter :: dp = selected_real_kind(15, 307) ! double precision
integer, parameter :: qp = selected_real_kind(32)      ! quadruple precision
real(kind=dp), parameter :: bad_real = -999.0_dp
integer, parameter :: i32=selected_int_kind(9), long_int = selected_int_kind(15), i64 = long_int, &
                      bad_int = -999
end module kind_mod
module util_mod
use kind_mod,only:dp,long_int,i64
implicit none
private
public::probe
real(kind=dp)    , parameter :: tiny_real = 1.0d-10, pi = 3.141592653589793238462643_dp, &
                                bad_real = -999.0_dp
integer          , parameter :: itrue = 1, ifalse = 0, istdin = 5, istdout = 6, bad_unit=-1, bad_int = -999
contains
function probe(x) result(y)
real(dp),intent(in)::x
real(dp)::y
y=x+pi
end function
end module
program main
use util_mod,only:probe
implicit none
print *,probe(2.0_8)
end program
