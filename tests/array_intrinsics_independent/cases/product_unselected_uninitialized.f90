program array_intrinsic_oracle
implicit none
integer :: aa(3)
logical :: mm(3)
aa(2)=7
mm=.false.
mm(2)=.true.
print *,product(aa,mm)
end program
