program rankthree
implicit none
integer :: aa(-1:1,2:3,4:6),bb(3,2,3),i,j,k
do k=4,6
do j=2,3
do i=-1,1
aa(i,j,k)=100*k+10*j+i
end do
end do
end do
bb=aa(:,:,:)+3
print *,aa(:,:,:),bb
print *,size(aa(:,:,:))
print *,size(aa(:,:,:),1),lbound(aa(:,:,:),1),ubound(aa(:,:,:),1)
print *,size(aa(:,:,:),2),lbound(aa(:,:,:),2),ubound(aa(:,:,:),2)
print *,size(aa(:,:,:),3),lbound(aa(:,:,:),3),ubound(aa(:,:,:),3)
end program rankthree
