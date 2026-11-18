module m
implicit none
integer::i=88
contains
subroutine work()
integer::i
print *, (i,i=1,3)
print *,i
end subroutine
end module
program main
use m
implicit none
call work()
print *,i
end program
