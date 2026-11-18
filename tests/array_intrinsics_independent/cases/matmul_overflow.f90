program array_intrinsic_oracle
implicit none
integer :: aa(2,2),bb(2,2)
print *,111
aa=50000
bb=50000
print *,matmul(aa,bb)
end program
