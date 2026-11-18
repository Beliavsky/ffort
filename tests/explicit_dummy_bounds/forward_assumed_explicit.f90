program main
implicit none
integer::a(7),n
a=[1,2,3,4,5,6,7]
n=5
call outer(a(7:1:-1),n)
print *,n,a
contains
subroutine outer(x,n)
integer,intent(inout)::n
integer,intent(inout)::x(-2:n-3)
n=2
call middle(x,n)
print *,size(x),lbound(x,1),ubound(x,1)
end subroutine
subroutine middle(y,m)
integer,intent(in)::m
integer,intent(inout)::y(:)
call inner(y,m)
end subroutine
subroutine inner(z,k)
integer,intent(in)::k
integer,intent(out)::z(k)
z=99
end subroutine
end program
