program array_intrinsic_oracle
implicit none
logical :: aa(2)
print *,111
aa=.true.
print *,minval(aa)
end program
