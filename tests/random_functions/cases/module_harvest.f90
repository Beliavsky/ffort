module m
real(8)::x
contains
real(8) function draw() result(r)
call random_number(x)
r=x
end function
end module
program p
use m
print *,draw()
end program
