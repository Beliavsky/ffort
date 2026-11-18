program main
implicit none
integer::a(0),b(0,3),c(2,0,2)
call one(a,-3)
call two(b,0)
call three(c,-2)
contains
subroutine one(x,n)
integer,intent(in)::n
integer,intent(out)::x(n)
x=7
print *,size(x),lbound(x,1),ubound(x,1)
end subroutine
subroutine two(x,n)
integer,intent(in)::n
integer,intent(out)::x(-2:n-3,4:6)
x=7
print *,shape(x),lbound(x,1),ubound(x,1),lbound(x,2),ubound(x,2)
end subroutine
subroutine three(x,n)
integer,intent(in)::n
integer,intent(out)::x(2,n,2)
x=7
print *,shape(x),lbound(x,2),ubound(x,2)
end subroutine
end program
