program main
implicit none
integer::a(2),n
a=1
call work(a,n)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n)
print *,size(x)
end subroutine
end program
