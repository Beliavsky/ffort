program array_intrinsic_oracle
implicit none
integer :: aa(2,0),bb(1,3),nn
nn=1
print *,111
print *,matmul(aa,bb(1:nn,:))
end program
