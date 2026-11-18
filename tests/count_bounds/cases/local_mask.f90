module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x
logical::local(2)
integer::a(count(local))

a=7
end subroutine
end module
program p
use m
implicit none
call work(1)
end program
