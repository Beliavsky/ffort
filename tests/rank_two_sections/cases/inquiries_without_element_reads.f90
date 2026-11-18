program section_oracle
implicit none
integer :: aa(-2:3,4:8)
print *,size(aa(3:-2:-2,8:4:-2)),size(aa(3,4:8))
print *,size(aa(:,5),1),lbound(aa(3:-2:-2,8:4:-2),2),ubound(aa(3:-2:-2,8:4:-2),2)
print *,size(aa(3:-2:-2,8:4:-2)+1),size(aa(3,:)+aa(-2,:))
end program section_oracle
