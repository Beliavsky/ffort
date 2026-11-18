program array_intrinsic_oracle
implicit none
logical :: aa(2,0),bb(0,3),cc(0)
print *,matmul(aa,bb),matmul(aa,cc),matmul(cc,bb)
end program
