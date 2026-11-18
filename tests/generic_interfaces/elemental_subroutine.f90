module ops
implicit none

interface test
module procedure a,b
end interface
contains
elemental subroutine a(x,y)
integer,intent(in)::x
integer,intent(out)::y
y=2*x
end subroutine
elemental subroutine b(x,y)
real,intent(in)::x
real,intent(out)::y
y=3*x
end subroutine
end module
program main
use ops
implicit none
integer::iv(3)=[1,2,3],ov(3)
real::rv(2)=[1.25,2.5],ro(2)
call test(iv,ov)
call test(rv,y=ro)
print *,ov,ro
end program
