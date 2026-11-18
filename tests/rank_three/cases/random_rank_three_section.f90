program rankthree
implicit none
real :: aa(2,2,3)
integer :: i,j,k,n
aa=-1.0
call random_number(aa(:,:,3:1:-2))
n=0
do k=1,3,2
do j=1,2
do i=1,2
if (aa(i,j,k)>=0.0.and.aa(i,j,k)<1.0) n=n+1
end do
end do
end do
print *,n,aa(:,:,2)
end program rankthree
