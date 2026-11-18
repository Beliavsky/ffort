program section_oracle
implicit none
real(8) :: aa(2,3)
aa=0.5d0
aa(1,1)=1.0d0
aa(2,3)=2.0d0
print *,exp(aa(2:1:-1,3:1:-2)),real(aa(:,2)),int(aa(:,1))
end program section_oracle
