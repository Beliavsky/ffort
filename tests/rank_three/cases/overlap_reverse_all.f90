program rankthree
implicit none
integer :: aa(-1:1,2:3,4:6),i,j,k
do k=4,6
do j=2,3
do i=-1,1
aa(i,j,k)=100*k+10*j+i
end do
end do
end do
aa(:,:,:)=aa(1:-1:-1,3:2:-1,6:4:-1)
print *,aa
end program rankthree
