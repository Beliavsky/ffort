program main
implicit none
integer::a(5)
a(4:5)=[44,55]
call work(a,3)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(inout)::x(n)
x=9
end subroutine
end program
