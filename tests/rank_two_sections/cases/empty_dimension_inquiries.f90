program section_oracle
implicit none
integer :: aa(-2:-3,4:8),bb(-2:3,4:3)
print *,size(aa(:,:)),size(aa(:,:),1),size(aa(:,:),2)
print *,lbound(aa(:,:),1),ubound(aa(:,:),1),lbound(aa(:,:),2),ubound(aa(:,:),2)
print *,size(bb(:,:)),size(bb(:,:),1),size(bb(:,:),2)
print *,lbound(bb(:,:),1),ubound(bb(:,:),1),lbound(bb(:,:),2),ubound(bb(:,:),2)
aa(:,:)=3
bb(:,:)=7
print *,aa(:,:),bb(:,:)
end program section_oracle
