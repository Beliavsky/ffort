program main
implicit none
integer::a(6),n
a=[1,2,3,4,5,6]
n=2
call work(a,n)
print *,n,a
n=4
call work(a,n)
print *,n,a
contains
subroutine work(x,n)
integer,intent(inout)::n
integer,intent(inout)::x(-1:n-2)
integer::scratch(size(x))
n=n+10
scratch=7
x=x+scratch
print *,size(x),lbound(x,1),ubound(x,1),size(scratch)
end subroutine
end program
