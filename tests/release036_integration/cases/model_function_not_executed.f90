module models
implicit none
integer::calls=0
contains
impure elemental function touch() result(x)
real(8)::x
calls=calls+1
x=3d0
end function
end module
program main
use models
implicit none
real(8)::a(2,2)
a=1d0
write(*,'("metadata:",5(1x,i0))')radix(touch()),kind(epsilon(touch())), &
kind(tiny(sign(touch(),-1d0))),kind(huge(log_gamma(touch()))),calls
write(*,'("array:",3(1x,i0))')kind(epsilon(dim(a([2,1],:),0d0))),radix(a),calls
end program
