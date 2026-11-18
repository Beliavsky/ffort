program control
implicit none
integer(8) :: i,n
integer :: j
n=0
do i=1,3_8
 n=n+i
end do
do j=4_8,1,-2_8
 n=n+j
end do
print *,n,i,j,kind(i),kind(j)
end program control
