program main
implicit none
integer::a(5)
a=1
call work(a,a,2)
contains
subroutine work(x,y,n)
integer,intent(in)::n
integer,intent(inout)::x(n)
integer,intent(in)::y(n)
x=y
end subroutine
end program
