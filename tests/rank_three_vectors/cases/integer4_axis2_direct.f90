program p
implicit none
integer(4)::a(3,3,3),b(3,2,3)
integer::i,j,k,idx(2)
do k=1,3
do j=1,3
do i=1,3
a(i,j,k)=i+3*(j-1)+9*(k-1)
end do
end do
end do
idx=[3,1]
b=a(:,idx,:)
do k=1,3
do j=1,2
do i=1,3
if(b(i,j,k)/=(i+3*(idx(j)-1)+9*(k-1)))error stop 1
end do
end do
end do
print '(i0)',1
end program
