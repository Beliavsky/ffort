program rankthree
implicit none
real(8) :: aa(2,3,4)
integer :: i,j,k,n
call random_number(aa)
n=0
do k=1,4
do j=1,3
do i=1,2
if (aa(i,j,k)>=0.0d0.and.aa(i,j,k)<1.0d0) n=n+1
end do
end do
end do
print *,size(aa),size(aa,3),n
end program rankthree
