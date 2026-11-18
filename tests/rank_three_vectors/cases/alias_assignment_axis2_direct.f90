program p
implicit none
integer::a(3,3,3),before(3,3,3),idx(3),i,j,k
do k=1,3
do j=1,3
do i=1,3
a(i,j,k)=i+3*(j-1)+9*(k-1)
end do
end do
end do
before=a
idx=[3,1,1]
a=a(:,idx,:)
do k=1,3
do j=1,3
do i=1,3
if(a(i,j,k)/=(i+3*(idx(j)-1)+9*(k-1)))error stop 1
end do
end do
end do
print '(i0)',1
end program
