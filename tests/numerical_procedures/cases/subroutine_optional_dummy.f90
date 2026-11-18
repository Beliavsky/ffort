module m
implicit none

contains
subroutine f(x)
real,intent(in),optional::x
print *,1
end subroutine f
end module m
program main
use m
implicit none

print *,777
call f()
end program main
