module m
implicit none

contains
subroutine f(x)
real,intent(in)::x
call f(x)
end subroutine f
end module m
program main
use m
implicit none

print *,777
call f(2.0)
end program main
