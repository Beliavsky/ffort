program array_intrinsic_oracle
implicit none
integer :: aa(4)
logical :: mm(4)
aa(1)=1
aa(2)=2
aa(3)=3
aa(4)=4
mm=.false.
mm(2)=.true.
mm(4)=.true.
print *,product(aa,1,mm)
end program
