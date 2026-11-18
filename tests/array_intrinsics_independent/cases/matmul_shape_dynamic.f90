program array_intrinsic_oracle
implicit none
integer :: aa(2,3),bb(3,2),nn
print *,111
aa=1
bb=2
nn=2
print *,matmul(aa,bb(1:nn,:))
end program
