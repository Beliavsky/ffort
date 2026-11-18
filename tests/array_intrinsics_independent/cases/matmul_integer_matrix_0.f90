program array_intrinsic_oracle
implicit none
integer :: aa(2,3),bb(3,4),cc(2,4)
aa(1,1)=2
aa(2,1)=3
aa(1,2)=1
aa(2,2)=2
aa(1,3)=0
aa(2,3)=1
bb(1,1)=-1
bb(2,1)=0
bb(3,1)=1
bb(1,2)=0
bb(2,2)=1
bb(3,2)=2
bb(1,3)=1
bb(2,3)=2
bb(3,3)=3
bb(1,4)=2
bb(2,4)=3
bb(3,4)=4
cc=matmul(aa,bb)
print *,cc,size(cc,1),size(cc,2)
print *,sum(matmul(aa,bb)),sum(matmul(aa,bb),1)
end program
