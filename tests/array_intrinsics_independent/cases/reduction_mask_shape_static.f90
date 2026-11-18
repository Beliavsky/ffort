program array_intrinsic_oracle
implicit none
integer :: aa(2,3)
logical :: mm(3,2)
print *,111
aa=1
mm=.true.
print *,sum(aa,mm)
end program
