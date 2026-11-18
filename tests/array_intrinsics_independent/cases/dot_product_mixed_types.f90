program array_intrinsic_oracle
implicit none
integer :: aa(3)
real(8)::bb(3)
aa=2
bb=0.25d0
print *,dot_product(aa,bb),dot_product(bb,aa)
end program
