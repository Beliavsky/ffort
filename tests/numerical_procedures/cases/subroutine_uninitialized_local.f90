module m
implicit none

contains
subroutine f(x)
real,intent(in)::x
real::y
print *,y
end subroutine f
end module m
program main
use m
implicit none

call f(2.0)
end program main
