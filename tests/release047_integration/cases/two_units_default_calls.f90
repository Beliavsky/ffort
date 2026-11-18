module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
contains
subroutine show(u)
integer,intent(in)::u
type(dt)::x
integer::n
read(u,*)n
x%a=x%a+n
print '(i3)',x%a
end subroutine
end module
program p
use types
implicit none

call show(27)
call show(28)
call show(27)
end program
