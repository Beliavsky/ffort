module m
implicit none
contains
subroutine host(x)
integer,intent(in)::x
call child()
contains
subroutine child()
call set_value(x)
end subroutine
end subroutine
subroutine set_value(x)
integer,intent(out)::x
x=3
end subroutine
end module
program p
use m
implicit none
call host(2)
end program
