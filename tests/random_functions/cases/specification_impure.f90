module m
contains
integer function width() result(r)
real::x
call random_number(x)
r=3
end function
subroutine fill(n)
integer,intent(in)::n
real::x(width())
x=0
end subroutine
end module
program p
use m
call fill(1)
end program
