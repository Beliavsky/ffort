program array_intrinsic_oracle
implicit none
integer :: aa(-2:-2,4:6),bb(7:9,-1:-1)
aa(-2,4)=1
aa(-2,5)=-1
aa(-2,6)=-5
bb(7,-1)=-1
bb(8,-1)=1
bb(9,-1)=0
print *,matmul(aa,bb)
print *,matmul(aa(-2:-2:-1,6:4:-1),bb(9:7:-1,-1:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
