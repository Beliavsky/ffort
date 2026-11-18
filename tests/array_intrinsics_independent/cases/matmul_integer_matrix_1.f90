program array_intrinsic_oracle
implicit none
integer :: aa(3,2),bb(2,1),cc(3,1)
aa(1,1)=2
aa(2,1)=3
aa(3,1)=4
aa(1,2)=1
aa(2,2)=2
aa(3,2)=3
bb(1,1)=-1
bb(2,1)=0
cc=matmul(aa,bb)
print *,cc,size(cc,1),size(cc,2)
print *,sum(matmul(aa,bb)),sum(matmul(aa,bb),1)
end program
