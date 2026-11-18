program array_intrinsic_oracle
implicit none
logical :: aa(3),bb(3),cc(0)
aa=.false.
bb=.true.
aa(2)=.true.
print *,dot_product(aa,bb)
bb(2)=.false.
print *,dot_product(aa,bb),dot_product(cc,cc)
end program
