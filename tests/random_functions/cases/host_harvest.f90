module m
contains
function outer() result(r)
real(8)::r,x
r=inner()
contains
real(8) function inner() result(y)
call random_number(x)
y=x
end function
end function
end module
program p
use m
print *,outer()
end program
