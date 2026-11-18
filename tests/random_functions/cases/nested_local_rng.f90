module m
contains
function outer() result(r)
real(8)::r
r=inner()
contains
real(8) function inner() result(x)
call random_number(x)
end function
end function
end module
program p
use m
real(8)::x
x=outer()
if(x<0d0.or.x>=1d0) error stop 1
print *,"PASS"
end program
