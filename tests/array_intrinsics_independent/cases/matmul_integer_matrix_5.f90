program array_intrinsic_oracle
implicit none
integer :: aa(2,3),bb(3,0),cc(2,0)
aa(1,1)=2
aa(2,1)=3
aa(1,2)=1
aa(2,2)=2
aa(1,3)=0
aa(2,3)=1

cc=matmul(aa,bb)
print *,cc,size(cc,1),size(cc,2)
print *,sum(matmul(aa,bb)),sum(matmul(aa,bb),1)
end program
