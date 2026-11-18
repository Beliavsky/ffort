program main
implicit none
integer::a(3,4)
a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
call work(a(3:1:-1,4:2:-2),2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(inout)::x(n,n)
x=x+100
end subroutine
end program
