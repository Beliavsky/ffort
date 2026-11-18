program array_intrinsic_oracle
implicit none
integer :: aa(3)
logical :: mm(3)
aa(2)=7
mm=.false.
mm(2)=.true.
print *,maxval(aa,mm)
end program
