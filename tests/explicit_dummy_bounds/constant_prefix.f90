program main
implicit none
integer :: a(5)
real :: b(4)
logical :: c(4)
a=[1,2,3,40,50]
b=[1.0,2.0,30.0,40.0]
c=[.true.,.false.,.true.,.false.]
call work(a,b,c)
print *,a,b,c
contains
subroutine work(x,y,z)
integer,intent(inout)::x(-1:1)
real,intent(inout)::y(2)
logical,intent(inout)::z(2)
x=x+10
y=y*2.0
z=.not.z
end subroutine
end program
