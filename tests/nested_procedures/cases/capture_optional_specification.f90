module m
implicit none
contains
subroutine host(n)
integer,intent(in),optional::n
call child()
contains
subroutine child()
integer::a(n)
a=1
print *,sum(a)
end subroutine
end subroutine
end module
program p
use m
implicit none
call host(2)
end program
