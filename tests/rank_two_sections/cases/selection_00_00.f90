program section_oracle
implicit none
integer :: aa(-2:3,4:8),bb(6,5),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *, aa(:,:)
print *,size(aa(:,:))
print *,size(aa(:,:),1)
print *,size(aa(:,:),2)
print *,lbound(aa(:,:),1),ubound(aa(:,:),1)
print *,lbound(aa(:,:),2),ubound(aa(:,:),2)
bb=aa(:,:)+2
print *,bb
aa(:,:)=aa(:,:)+1000
print *,aa
end program section_oracle
