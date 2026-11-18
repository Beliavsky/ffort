program main
implicit none
integer(kind=8)::a(3),n
real(kind=8)::b(3)
a=[10000000000_8,20000000000_8,30000000000_8]
b=[1.25_8,2.5_8,9.0_8]
n=2_8
call work(a,b,n)
print *,a,b
contains
subroutine work(x,y,n)
integer(kind=8),intent(in)::n
integer(kind=8),intent(inout)::x(n)
real(kind=8),intent(inout)::y(n)
x=x+1_8
y=y*2.0_8
end subroutine
end program
