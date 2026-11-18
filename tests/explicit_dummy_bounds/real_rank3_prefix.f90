program main
implicit none
real::a(1,2,3)
a=2.5
call work(a,2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
real,intent(inout)::x(n,1,n)
x=x+1.25
end subroutine
end program
