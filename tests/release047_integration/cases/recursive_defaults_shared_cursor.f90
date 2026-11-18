module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
contains
recursive subroutine visit(u,depth)
integer,intent(in)::u,depth
type(dt)::x
integer::n
read(u,*)n
x%a=x%a+n
if(depth>1)call visit(u,depth-1)
print '(i3)',x%a
end subroutine
end module
program p
use types
implicit none

call visit(27,2)
end program
