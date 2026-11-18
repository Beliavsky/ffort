module m
implicit none
contains
subroutine outer()
integer::i
i=88
call work()
print *,i
contains
subroutine work()
integer::a(3)
a=[(i,i=1,3)]
print *,a,i
end subroutine
end subroutine
end module
program main
use m
implicit none
call outer()
end program
