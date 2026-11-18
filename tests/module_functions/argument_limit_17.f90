module m

contains
function sumall(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17) result(y)
integer,intent(in) :: a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17
integer :: y
y=a1+a2+a3+a4+a5+a6+a7+a8+a9+a10+a11+a12+a13+a14+a15+a16+a17
end function sumall
end module m
program main
use m
implicit none

print *, sumall(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17)
end program main
