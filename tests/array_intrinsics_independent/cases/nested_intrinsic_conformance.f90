program array_intrinsic_oracle
implicit none
integer :: aa(2,3),bb(3,2),cc(2,2)
aa=2
bb=3
cc=matmul(aa,bb)
print *,sum(cc),sum(matmul(aa,bb),2)
print *,matmul(aa,bb)+cc,product(sum(matmul(aa,bb),1))
end program
