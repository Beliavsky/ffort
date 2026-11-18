program main
implicit none
integer::a(1,3,3),j,k
do k=1,3
do j=1,3
a(1,j,k)=j+(k-1)*3
end do
end do
a(1,3,3)=90
call work(a,2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(inout)::x(-1:0,3:n+2,0:1)
print *,shape(x),x(-1,3,0),x(0,4,1)
x=x*2
end subroutine
end program
