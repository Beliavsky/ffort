module utility_slice
implicit none
private
public :: dp,long_int,i64,sech
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
elemental function sech(xx) result(yy)
! hyperbolic secant
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 1/cosh(xx)
end function sech

end module
program test_slice
use utility_slice
implicit none
print *, sech([0.0_dp,1.0_dp])
end program
