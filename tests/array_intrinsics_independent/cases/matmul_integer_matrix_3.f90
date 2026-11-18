program array_intrinsic_oracle
implicit none
integer :: aa(0,3),bb(3,2),cc(0,2)

bb(1,1)=-1
bb(2,1)=0
bb(3,1)=1
bb(1,2)=0
bb(2,2)=1
bb(3,2)=2
cc=matmul(aa,bb)
print *,cc,size(cc,1),size(cc,2)
print *,sum(matmul(aa,bb)),sum(matmul(aa,bb),1)
end program
