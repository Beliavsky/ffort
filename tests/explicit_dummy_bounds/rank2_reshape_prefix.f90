program main
implicit none
integer::a(2,4)
a=reshape([1,2,3,4,5,6,70,80],[2,4])
call work(a,3)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(inout)::x(0:n-1,-2:-1)
print *,size(x,1),size(x,2),x(0,-2),x(2,-1)
x=x+10
end subroutine
end program
