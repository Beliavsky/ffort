program main
implicit none
integer::a(4)
a=9
call work(a,2)
print *,a(2)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(out)::x(n)
x(1)=7
end subroutine
end program
