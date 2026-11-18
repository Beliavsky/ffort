module m
interface bessel_yn
module procedure f
end interface
contains
real(8) function f(n,x)
integer,intent(in)::n
real(8),intent(in)::x
f=n+x
end function
end module
program p
use m
print *,bessel_yn(2,3d0)
end program
