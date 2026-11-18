program array_intrinsic_oracle
implicit none
integer :: aa(4),bb(4),nn
print *,111
aa=1
bb=2
nn=3
print *,dot_product(aa,bb(1:nn))
end program
