program p
implicit none
integer,allocatable::a(:,:,:)
integer::idx(2),i,j,k
allocate(a(3,3,3))
do k=1,3
do j=1,3
do i=1,3
a(i,j,k)=i+3*(j-1)+9*(k-1)
end do
end do
end do
idx=[3,1]
a=a(:,:,idx)
if(any(shape(a)/=[3,3,2]))error stop 1
do k=1,2
do j=1,3
do i=1,3
if(a(i,j,k)/=(i+3*(j-1)+9*(idx(k)-1)))error stop 2
end do
end do
end do
print '(i0)',1
end program
