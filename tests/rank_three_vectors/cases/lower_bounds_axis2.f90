program p
implicit none
integer::a(-2:0,4:6,-5:-3),b(3,3,3),idx(3),i,j,k
do k=-5,-3
do j=4,6
do i=-2,0
a(i,j,k)=i+10*j+100*k
end do
end do
end do
idx=[6,4,6]
b=a(:,idx,:)
do k=1,3
do j=1,3
do i=1,3
if(b(i,j,k)/=(i-3)+10*idx(j)+100*(k-6))error stop 1
end do
end do
end do
print '(i0)',1
end program
