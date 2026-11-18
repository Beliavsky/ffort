program main
implicit none
integer::a(2)
a=1
call work(a,3)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n)
print *,x
end subroutine
end program
