program main
implicit none
integer::a(131072)
a=1
call work(a,131072)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n)
print *,size(x),sum(x)
end subroutine
end program
