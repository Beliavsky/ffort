program array_intrinsic_oracle
implicit none
integer :: aa(-1:1,4:5)
logical :: mm(6:8,-3:-2)
aa(:,4)=2
aa(:,5)=3
mm=.false.
mm(6,-3)=.true.
mm(8,-2)=.true.
print *,sum(aa,mm),sum(aa,1,mm),sum(aa,2,mm)
end program
