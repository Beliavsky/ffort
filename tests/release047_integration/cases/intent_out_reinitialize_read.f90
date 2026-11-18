module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
contains
subroutine reset(x,u)
type(dt),intent(out)::x
integer,intent(in)::u
integer::n
print '(i3,f5.1)',x%a,x%y
read(u,*)n
x%a=n
end subroutine
end module
program p
use types
implicit none
type(dt)::x
x=dt(99,8.)
call reset(x,27)
print '(i3,f5.1)',x%a,x%y
end program
