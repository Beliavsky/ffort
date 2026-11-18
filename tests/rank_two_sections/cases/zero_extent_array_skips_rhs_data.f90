program section_oracle
implicit none
integer :: aa(3,3),vv,zz
aa=7
aa(2:1,:)=aa(2:1,:)+vv
print *,aa,size(aa(:,2:1)+vv)
zz=0
aa(:,2:1)=aa(:,2:1)+1/zz
print *,aa
end program section_oracle
