module operations
implicit none

interface twice
module procedure ints,reals
end interface
contains
subroutine ints(x,y)
integer,intent(in)::x
integer,intent(out)::y
y=2*x
end subroutine
subroutine reals(x,y)
real,intent(in)::x
real,intent(out)::y
y=2*x
end subroutine
end module
program main
use operations
implicit none
integer::i
real::r
call twice(5,i)
call twice(y=r,x=1.25)
print *,i,r
end program
