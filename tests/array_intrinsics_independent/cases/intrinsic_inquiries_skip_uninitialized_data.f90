program array_intrinsic_oracle
implicit none
integer :: aa(2,3),bb(3,4)
print *,size(sum(aa,1)),size(sum(aa,2)),lbound(sum(aa,1),1),ubound(sum(aa,2),1)
print *,size(matmul(aa,bb)),size(matmul(aa,bb),1),size(matmul(aa,bb),2)
end program
