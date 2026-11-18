module m
implicit none
integer::i=88
contains
subroutine work()
integer::a(3)
a=[(i,i=1,3)]
print *,a,i
end subroutine
end module
program main
use m
implicit none
call work()
print *,i
end program
