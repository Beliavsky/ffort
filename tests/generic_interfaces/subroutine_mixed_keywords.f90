module operations
implicit none

interface choose
module procedure a,b
end interface
contains
subroutine a(x,y)
integer,intent(in)::x
integer,intent(out)::y
y=2*x
end subroutine
subroutine b(x,y)
real,intent(in)::x
real,intent(out)::y
y=3*x
end subroutine
end module
program main
use operations
implicit none
integer::i
real::r
call choose(4,y=i)
call choose(1.25,y=r)
print *,i,r

end program
