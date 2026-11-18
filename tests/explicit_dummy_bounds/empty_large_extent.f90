program main
implicit none
integer::a(0,0)
call work(a,2147483647)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(out)::x(n,0)
x=1
print *,shape(x),size(x)
end subroutine
end program
