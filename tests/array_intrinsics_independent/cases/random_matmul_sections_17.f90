program array_intrinsic_oracle
implicit none
integer :: aa(-2:0,4:4),bb(7:7,-1:0)
aa(-2,4)=5
aa(-1,4)=-1
aa(0,4)=-2
bb(7,-1)=-4
bb(7,0)=3
print *,matmul(aa,bb)
print *,matmul(aa(0:-2:-1,4:4:-1),bb(7:7:-1,0:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
