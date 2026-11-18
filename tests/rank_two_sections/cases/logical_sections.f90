program section_oracle
implicit none
logical :: aa(2,3)
aa=.false.
aa(1,:)=.true.
print *,aa(:,3:1:-1),.not.aa(1,:),aa(1,:).and.aa(2,:)
aa(:,2:3)=.not.aa(:,1:2)
print *,aa
end program section_oracle
