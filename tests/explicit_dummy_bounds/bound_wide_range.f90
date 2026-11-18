program main
implicit none
integer::a(1)
a=1
call work(a,2147483648_8)
contains
subroutine work(x,n)
integer(kind=8),intent(in)::n
integer,intent(in)::x(n)
print *,size(x)
end subroutine
end program
