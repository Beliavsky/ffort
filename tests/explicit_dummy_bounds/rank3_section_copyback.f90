program main
implicit none
integer::a(2,2,3),i,j,k
do k=1,3
do j=1,2
do i=1,2
a(i,j,k)=i+2*(j-1)+4*(k-1)
end do
end do
end do
call work(a(2:1:-1,2:1:-1,3:1:-2),2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(out)::x(1,n,n)
x=50
end subroutine
end program
