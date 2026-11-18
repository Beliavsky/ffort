module types
implicit none
type::dt
integer::a=7
end type
contains
recursive subroutine show(n)
integer,intent(in)::n
type(dt)::v
print '(i0)',v%a
v%a=n
if(n>0)call show(n-1)
print '(i0)',v%a
end subroutine
end module
program p
use types
implicit none
call show(2)
end program
