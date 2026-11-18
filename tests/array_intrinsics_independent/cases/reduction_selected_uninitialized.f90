program array_intrinsic_oracle
implicit none
integer :: aa(2)
logical :: mm(2)
print *,111
aa(1)=3
mm=.true.
print *,sum(aa,mm)
end program
