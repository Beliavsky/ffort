program array_intrinsic_oracle
implicit none
integer :: aa(3,0),bb(0,2),cc(3,2)


cc=matmul(aa,bb)
print *,cc,size(cc,1),size(cc,2)
print *,sum(matmul(aa,bb)),sum(matmul(aa,bb),1)
end program
