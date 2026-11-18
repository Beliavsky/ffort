program p
implicit none
integer::a(3,3,3),idx(1),i,j,k
integer,allocatable::b(:,:,:)
a(:,2,:)=9
idx=[2]
b=a(:,idx,:)
do k=1,3
do j=1,1
do i=1,3
if(b(i,j,k)/=9)error stop 1
end do
end do
end do
print '(i0)',1
end program
