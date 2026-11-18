program array_intrinsic_oracle
implicit none
integer :: aa(2)
logical :: bb(2)
print *,111
aa=1
bb=.true.
print *,dot_product(aa,bb)
end program
