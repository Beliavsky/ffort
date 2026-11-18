program main
implicit none
integer::a(5),n
a=[1,2,3,4,5]
n=3
call work(x=a,n=n)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(inout)::x(0:n-1)
x=x+n
end subroutine
end program
