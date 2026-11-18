program main
implicit none
integer::a(1)
a=1
call work(a,2147483647)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n+1)
print *,size(x)
end subroutine
end program
