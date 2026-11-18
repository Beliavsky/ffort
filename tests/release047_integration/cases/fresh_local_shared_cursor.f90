module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
contains
subroutine show(unit)
integer,intent(in)::unit
type(dt)::x
integer::n
read(unit,*)n
print '(2i3)',x%a,n
x%a=99
end subroutine
end module
program p
use types
implicit none

call show(27)
call show(27)
end program
