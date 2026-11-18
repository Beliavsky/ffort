program main
implicit none
integer::a(4)
a(1)=7
call work(a,2)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n)
print *,x(2)
end subroutine
end program
