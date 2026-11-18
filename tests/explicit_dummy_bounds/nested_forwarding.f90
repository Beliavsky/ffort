program main
implicit none
integer::a(7)
a=[1,2,3,4,5,6,7]
call outer(a(7:1:-1),5)
print *,a
contains
subroutine outer(x,n)
integer,intent(in)::n
integer,intent(inout)::x(-2:n-3)
call inner(x(-1:1),2)
end subroutine
subroutine inner(y,m)
integer,intent(in)::m
integer,intent(out)::y(m)
y=80
end subroutine
end program
