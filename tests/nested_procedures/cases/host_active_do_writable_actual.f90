module m
implicit none
contains
subroutine host()
integer::i
do i=1,3
call child()
end do
contains
subroutine child()
call set_value(i)
end subroutine
end subroutine
subroutine set_value(x)
integer,intent(out)::x
x=9
end subroutine
end module
program p
use m
implicit none
call host()
end program
