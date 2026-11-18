program array_intrinsic_oracle
implicit none
real(8) :: aa(2,2)
real :: bb(2,2)
aa=0.1d0
bb=0.5
print *,matmul(aa,bb),matmul(bb,aa)
end program
