program array_intrinsic_oracle
implicit none
integer :: aa(-2:-2,4:7),bb(7:10,-1:0)
aa(-2,4)=-4
aa(-2,5)=1
aa(-2,6)=-4
aa(-2,7)=4
bb(7,-1)=1
bb(8,-1)=1
bb(9,-1)=2
bb(10,-1)=-1
bb(7,0)=-3
bb(8,0)=-3
bb(9,0)=5
bb(10,0)=-5
print *,matmul(aa,bb)
print *,matmul(aa(-2:-2:-1,7:4:-1),bb(10:7:-1,0:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
