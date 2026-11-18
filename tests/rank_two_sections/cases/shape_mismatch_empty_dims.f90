program section_oracle
implicit none
integer :: aa(3,3),nn
nn=2
print *,111
aa(nn:1,:)=aa(:,nn:1)
end program section_oracle
