program main
implicit none
integer::a(1)
a=1
call work(a,0)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(1/n)
print *,size(x)
end subroutine
end program
