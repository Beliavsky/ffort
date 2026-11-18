program main
implicit none
integer::a(8)
a=[1,2,3,4,5,6,7,8]
call work(a(8:2:-2),3)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(out)::x(n)
x=[10,20,30]
end subroutine
end program
