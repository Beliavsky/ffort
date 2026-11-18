module m
implicit none
contains
subroutine work(x)
logical,intent(out)::x(:)

integer::a(count(x))

a=7
end subroutine
end module
program p
use m
implicit none
logical::v(3)
call work(v)
end program
