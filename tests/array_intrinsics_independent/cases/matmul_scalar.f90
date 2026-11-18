program array_intrinsic_oracle
implicit none
integer :: aa(2,2),bb
print *,111
aa=1
bb=2
print *,matmul(aa,bb)
end program
