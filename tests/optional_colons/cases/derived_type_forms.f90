module m
implicit none
type box
integer n
real(8) x
logical valid
end type
end module
program p
use m
implicit none
type(box) a,b
a=box(3,2.5_8,.true.)
b=a
print *,b%n,b%x,b%valid
end program
